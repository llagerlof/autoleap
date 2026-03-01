# autoleap.sh
#
# Enhances `cd` with directory history tracking and intelligent path matching
#
# Version: 3.0.0
# Author:  Lawrence Lagerlof <llagerlof@gmail.com>
# GitHub:  http://github.com/llagerlof/autoleap
# License: MIT

# ── Helper functions (prefixed to avoid namespace pollution) ─────────────────

# Escape special regex metacharacters for safe use in grep patterns
_autoleap_escape_regex() {
    printf '%s' "$1" | sed 's/[].[\\*^$()+?{|]/\\&/g'
}

# Update history file with the current directory (best-effort, never fatal)
_autoleap_update_history() {
    { touch ~/.autoleap.history 2>/dev/null &&
      grep -qxF "$PWD" ~/.autoleap.history 2>/dev/null ||
      echo "$PWD" >> ~/.autoleap.history 2>/dev/null; } 2>/dev/null
    return 0
}

# Remove a path from history using fixed-string matching (safe, no injection)
_autoleap_remove_from_history() {
    local path_to_remove="$1"
    { grep -vxF "$path_to_remove" ~/.autoleap.history > ~/.autoleap.history.tmp &&
      mv ~/.autoleap.history.tmp ~/.autoleap.history; } 2>/dev/null
    return 0
}

# Resolve the best destination from a history path.
# Finds the deepest path component matching the search argument and returns
# the path truncated to that component.
_autoleap_resolve_destination() {
    local path_found="$1"
    local search_arg="$2"
    local IFS_backup destination

    IFS_backup=$IFS
    IFS='/'
    local path_parts=($path_found)
    IFS=$IFS_backup

    local best_index=-1
    for ((i=${#path_parts[@]}-1; i>=0; i--)); do
        if [[ "${path_parts[i]}" == *"$search_arg"* ]]; then
            best_index=$i
            break
        fi
    done

    if [ $best_index -ge 0 ]; then
        destination=$(IFS='/'; printf '/%s' "${path_parts[@]:0:$((best_index+1))}")
        destination=${destination:1}  # Remove leading double slash
    else
        destination="$path_found"
    fi

    printf '%s' "$destination"
}

# ── Main cd function ─────────────────────────────────────────────────────────

cd () {
    # ── Always try builtin cd first ──────────────────────────────────────
    # This preserves ALL standard cd behavior: CDPATH, cd -, cd old new,
    # symbolic link options (-P/-L/-e), etc.
    builtin cd "$@" 2>/dev/null && {
        _autoleap_update_history
        return 0
    }

    # ── Parse arguments to extract path for autoleap matching ────────────
    local options=()
    local path_argument=""
    local found_double_dash=false

    for arg in "$@"; do
        if $found_double_dash; then
            path_argument="$arg"
            break
        elif [[ "$arg" == "--" ]]; then
            options+=("$arg")
            found_double_dash=true
        elif [[ "$arg" == -* ]]; then
            options+=("$arg")
        else
            path_argument="$arg"
        fi
    done

    # If no path argument was found, autoleap can't help — show builtin error
    if [ -z "$path_argument" ]; then
        builtin cd "$@"
        return $?
    fi

    # ── Autoleap history matching ────────────────────────────────────────
    local history_contents=()
    local path_found destination escaped_arg
    local all_matches=()

    # Load history (most recent entries first)
    if [ -f ~/.autoleap.history ]; then
        while IFS= read -r line; do
            history_contents=("$line" "${history_contents[@]}")
        done < ~/.autoleap.history
    fi

    # No history — nothing to match
    if [ ${#history_contents[@]} -eq 0 ]; then
        builtin cd "$@"
        return $?
    fi

    # Escape regex metacharacters in the search argument for safe grep usage
    escaped_arg=$(_autoleap_escape_regex "$path_argument")

    if command -v fzf >/dev/null 2>&1; then
        # ── fzf-enabled path ─────────────────────────────────────────────
        local dir_matches=() basename_matches=() substring_matches=()

        # Exact tail match: paths ending with /arg
        mapfile -t dir_matches < <(printf '%s\n' "${history_contents[@]}" | grep "/${escaped_arg}$")

        # Basename ends with arg
        mapfile -t basename_matches < <(printf '%s\n' "${history_contents[@]}" | grep "/[^/]*${escaped_arg}$")

        # Substring match anywhere in the path (fixed-string, no regex)
        mapfile -t substring_matches < <(printf '%s\n' "${history_contents[@]}" | grep -F "$path_argument")

        if [ ${#dir_matches[@]} -gt 1 ] || [ ${#basename_matches[@]} -gt 1 ] || [ ${#substring_matches[@]} -gt 1 ]; then
            # Multiple matches — combine without duplicates, filter to existing dirs
            all_matches=()
            for match in "${dir_matches[@]}" "${basename_matches[@]}" "${substring_matches[@]}"; do
                if [ -d "$match" ] && ! printf '%s\n' "${all_matches[@]}" | grep -qxF "$match"; then
                    all_matches+=("$match")
                fi
            done

            if [ ${#all_matches[@]} -gt 1 ]; then
                # Sort by match quality (best first, since fzf shows first item at bottom):
                #   2 = basename exactly equals query  (best — appears at bottom/cursor)
                #   1 = basename contains query
                #   0 = no basename match               (worst — appears at top)
                # Within each group, shallower paths first (deeper paths toward the top).
                mapfile -t all_matches < <(
                    printf '%s\n' "${all_matches[@]}" | awk -v q="$path_argument" '{
                        n = split($0, parts, "/")
                        score = (parts[n] == q) ? 2 : ((index(parts[n], q) > 0) ? 1 : 0)
                        printf "%d\t%d\t%s\n", score, n, $0
                    }' | sort -t'	' -k1,1rn -k2,2n | cut -f3-
                )

                destination=$(printf '%s\n' "${all_matches[@]}" | fzf --no-sort --height 20% --prompt="Select directory: ")
                if [ -n "$destination" ]; then
                    builtin cd "${options[@]}" "$destination" && {
                        _autoleap_update_history
                        return 0
                    }
                fi
                # User cancelled fzf or cd failed
                return 1
            fi
        fi

        # Single or no fzf-worthy matches — use first match from prioritized search
        path_found=$({
            printf '%s\n' "${history_contents[@]}" | grep "/${escaped_arg}$" | head -n1
            printf '%s\n' "${history_contents[@]}" | grep "/[^/]*${escaped_arg}$" | head -n1
            printf '%s\n' "${history_contents[@]}" | grep -F "$path_argument" | head -n1
        } | head -n1)
    else
        # ── No fzf — use first match from prioritized search ─────────────
        path_found=$({
            printf '%s\n' "${history_contents[@]}" | grep "/${escaped_arg}$" | head -n1
            printf '%s\n' "${history_contents[@]}" | grep "/[^/]*${escaped_arg}$" | head -n1
            printf '%s\n' "${history_contents[@]}" | grep -F "$path_argument" | head -n1
        } | head -n1)
    fi

    # Try to resolve and cd to the matched history entry
    if [ -n "$path_found" ]; then
        destination=$(_autoleap_resolve_destination "$path_found" "$path_argument")

        if [ -d "$destination" ]; then
            builtin cd "${options[@]}" "$destination" && {
                _autoleap_update_history
                return 0
            }
        else
            _autoleap_remove_from_history "$path_found"
            echo "Removed invalid path: $path_found" >&2
        fi
    fi

    # ── Final fallback — let builtin cd show its standard error message ──
    builtin cd "$@"
}
