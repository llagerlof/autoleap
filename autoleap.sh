# autoleap.sh
#
# Autoleap is a bash script that improves the `cd` command, allowing quick access to previously accessed directories.
#
# Version: 1.0.3
# Author:  Lawrence Lagerlof <llagerlof@gmail.com>
# GitHub:  http://github.com/llagerlof/autoleap
# License: https://opensource.org/licenses/MIT

cd () {
    # If the builtin cd fails, try to find the path argument in history file
    if ! builtin cd "$@" >/dev/null 2>&1; then

        # Extract the directory path from the possible cd arguments
        path_argument=""
        for arg in "$@"; do
            if [ $arg != "-" ] && [ $arg != "--" ] && [ $arg != "-L" ] && [ $arg != "-P" ]; then
                path_argument=$arg
            fi
        done

        # The actual search in history file only happens if a valid path argument was found
        if [ "$path_argument" != "" ]; then

            # Initialize the history file
            if [ ! -f ~/.autoleap.history ]
            then
                touch ~/.autoleap.history
            fi

            # Store two possible history entries.
            line_end_found=`tac ~/.autoleap.history | grep "$path_argument$" | head -n1`
            line_found=`tac ~/.autoleap.history | grep "$path_argument" | head -n1`

            # Gives preference to path_argument at the end of line in history (leap to most inner directory, if available)
            if test -d "$line_end_found"; then
                destination=$line_end_found
            elif test -d "$line_found"; then
                destination=$line_found
            else
                destination=$path_argument
            fi

            builtin cd "$destination"
        fi
    fi

    # Add current path to history only if does not exist in history file
    pwd_history=`grep -x "$PWD" ~/.autoleap.history | head -n1`
    if [ "$pwd_history" = "" ]; then
        echo $PWD >> ~/.autoleap.history
    fi

    # Reset local variables
    unset path_argument
    unset line_end_found
    unset line_found
    unset destination
    unset pwd_history
}
