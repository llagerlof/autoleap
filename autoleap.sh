# autoleap.sh
#
# Enhances `cd` with directory history tracking and intelligent path matching
#
# Version: 2.0.1
# Author:  Lawrence Lagerlof <llagerlof@gmail.com>
# GitHub:  http://github.com/llagerlof/autoleap
# License: MIT

cd () {
    local options=()
    local path_argument=""
    local found_double_dash=false
    local exit_status=0
    local history_contents path_dirname_found path_end_found path_any_found
    local path_found destination IFS_backup
    local all_matches=()

    # Parse arguments
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

    # Initialize history file
    touch ~/.autoleap.history 2>/dev/null || { echo "Cannot create history file"; return 1; }

    # Try normal cd first
    if [ -d "$path_argument" ] || [ -z "$path_argument" ]; then
        if [ -z "$path_argument" ]; then
            # When no argument is provided, go to home directory
            builtin cd "${options[@]}"
        else
            builtin cd "${options[@]}" "$path_argument"
        fi
        exit_status=$?
    else
        # Check if fzf is available
        if command -v fzf >/dev/null 2>&1; then
            # Load history contents
            history_contents=()
            while IFS= read -r line; do
                history_contents=("$line" "${history_contents[@]}")
            done < ~/.autoleap.history

            # Find directories that end with the path_argument (e.g., /xxx/ccc or /yyy/ccc)
            # Use grep without -F to properly use regex anchors
            mapfile -t dir_matches < <(printf '%s\n' "${history_contents[@]}" | grep "/$path_argument$")
            
            # Find directories whose final component exactly matches path_argument
            mapfile -t basename_matches < <(printf '%s\n' "${history_contents[@]}" | grep "/[^/]*$path_argument$")

            # If we have multiple matches, use fzf to select
            if [ ${#dir_matches[@]} -gt 1 ] || [ ${#basename_matches[@]} -gt 1 ]; then
                # Combine all matches without duplicates
                all_matches=()
                for match in "${dir_matches[@]}" "${basename_matches[@]}"; do
                    if [ -d "$match" ] && ! printf '%s\n' "${all_matches[@]}" | grep -qx "$match"; then
                        all_matches+=("$match")
                    fi
                done

                if [ ${#all_matches[@]} -gt 1 ]; then
                    destination=$(printf '%s\n' "${all_matches[@]}" | fzf --height 20% --prompt="Select directory: ")
                    if [ -n "$destination" ]; then
                        builtin cd "${options[@]}" "$destination"
                        exit_status=$?
                    else
                        # User cancelled fzf selection
                        return 1
                    fi
                else
                    # Fall back to original logic if we only have one valid match after filtering
                    path_found=$({
                        printf '%s\n' "${history_contents[@]}" | grep "/$path_argument$" | head -n1
                        printf '%s\n' "${history_contents[@]}" | grep "/[^/]*$path_argument$" | head -n1
                        printf '%s\n' "${history_contents[@]}" | grep -F "$path_argument" | head -n1
                    } | head -n1)

                    if [ -n "$path_found" ]; then
                        IFS_backup=$IFS
                        IFS='/'
                        local path_parts=($path_found)
                        IFS=$IFS_backup
                        
                        local best_index=-1
                        for ((i=${#path_parts[@]}-1; i>=0; i--)); do
                            if [[ "${path_parts[i]}" == *"$path_argument"* ]]; then
                                best_index=$i
                                break
                            fi
                        done
                        
                        if [ $best_index -ge 0 ]; then
                            destination=$(IFS='/'; printf '/%s' "${path_parts[@]:0:$((best_index+1))}")
                            destination=${destination:1}  # Remove leading slash
                        else
                            destination="$path_found"
                        fi

                        # Validate and cd
                        if [ ! -d "$destination" ]; then
                            # Remove the original path_found from history, not the derived destination
                            sed "\:^${path_found//:/\\:}$:d" ~/.autoleap.history > ~/.autoleap.history.tmp &&
                            mv ~/.autoleap.history.tmp ~/.autoleap.history
                            echo "Removed invalid path: $path_found"
                            exit_status=1
                        else
                            builtin cd "${options[@]}" "$destination"
                            exit_status=$?
                        fi
                    else
                        builtin cd "${options[@]}" "$path_argument" 2>/dev/null
                        exit_status=$?
                        [ $exit_status -ne 0 ] && echo "cd: $path_argument: No such file or directory"
                    fi
                fi
            else
                # Fall back to original logic for single or no matches
                path_found=$({
                    printf '%s\n' "${history_contents[@]}" | grep "/$path_argument$" | head -n1
                    printf '%s\n' "${history_contents[@]}" | grep "/[^/]*$path_argument$" | head -n1
                    printf '%s\n' "${history_contents[@]}" | grep -F "$path_argument" | head -n1
                } | head -n1)

                if [ -n "$path_found" ]; then
                    IFS_backup=$IFS
                    IFS='/'
                    local path_parts=($path_found)
                    IFS=$IFS_backup
                    
                    local best_index=-1
                    for ((i=${#path_parts[@]}-1; i>=0; i--)); do
                        if [[ "${path_parts[i]}" == *"$path_argument"* ]]; then
                            best_index=$i
                            break
                        fi
                    done
                    
                    if [ $best_index -ge 0 ]; then
                        destination=$(IFS='/'; printf '/%s' "${path_parts[@]:0:$((best_index+1))}")
                        destination=${destination:1}  # Remove leading slash
                    else
                        destination="$path_found"
                    fi

                    # Validate and cd
                    if [ ! -d "$destination" ]; then
                        # Remove the original path_found from history, not the derived destination
                        sed "\:^${path_found//:/\\:}$:d" ~/.autoleap.history > ~/.autoleap.history.tmp &&
                        mv ~/.autoleap.history.tmp ~/.autoleap.history
                        echo "Removed invalid path: $path_found"
                        exit_status=1
                    else
                        builtin cd "${options[@]}" "$destination"
                        exit_status=$?
                    fi
                else
                    builtin cd "${options[@]}" "$path_argument" 2>/dev/null
                    exit_status=$?
                    [ $exit_status -ne 0 ] && echo "cd: $path_argument: No such file or directory"
                fi
            fi
        else
            # fzf not available, use original logic
            history_contents=()
            while IFS= read -r line; do
                history_contents=("$line" "${history_contents[@]}")
            done < ~/.autoleap.history

            path_found=$({
                printf '%s\n' "${history_contents[@]}" | grep "/$path_argument$" | head -n1
                printf '%s\n' "${history_contents[@]}" | grep "/[^/]*$path_argument$" | head -n1
                printf '%s\n' "${history_contents[@]}" | grep -F "$path_argument" | head -n1
            } | head -n1)

            if [ -n "$path_found" ]; then
                IFS_backup=$IFS
                IFS='/'
                local path_parts=($path_found)
                IFS=$IFS_backup
                
                local best_index=-1
                for ((i=${#path_parts[@]}-1; i>=0; i--)); do
                    if [[ "${path_parts[i]}" == *"$path_argument"* ]]; then
                        best_index=$i
                        break
                    fi
                done
                
                if [ $best_index -ge 0 ]; then
                    destination=$(IFS='/'; printf '/%s' "${path_parts[@]:0:$((best_index+1))}")
                    destination=${destination:1}  # Remove leading slash
                else
                    destination="$path_found"
                fi

                # Validate and cd
                if [ ! -d "$destination" ]; then
                    # Remove the original path_found from history, not the derived destination
                    sed "\:^${path_found//:/\\:}$:d" ~/.autoleap.history > ~/.autoleap.history.tmp &&
                    mv ~/.autoleap.history.tmp ~/.autoleap.history
                    echo "Removed invalid path: $path_found"
                    exit_status=1
                else
                    builtin cd "${options[@]}" "$destination"
                    exit_status=$?
                fi
            else
                builtin cd "${options[@]}" "$path_argument" 2>/dev/null
                exit_status=$?
                [ $exit_status -ne 0 ] && echo "cd: $path_argument: No such file or directory"
            fi
        fi
    fi

    # Update history after successful cd
    if [ $exit_status -eq 0 ]; then
        if ! grep -qxF "$PWD" ~/.autoleap.history; then
            echo "$PWD" >> ~/.autoleap.history
        fi
    fi

    return $exit_status
}
