cd () {
    # Reset local variables
    unset path_argument
    unset line_found

    # Extract the directory path from arguments
    for arg in "$@"; do
        if [ $arg != -* ]; then
            path_argument=$arg
        fi
    done

    if [ -v path_argument ]; then
        # If the path_argument is a directory that exists, access it
        if [ -d "$path_argument" ]; then
            builtin cd "$@"
        # If path_argument is not a directory that exists, search a valid path in history file
        else
            line_end_found=`tac ~/.autoleap.history | grep "$path_argument$" | head -n1`
            line_found=`tac ~/.autoleap.history | grep "$path_argument" | head -n1`

            if test -d "$line_end_found"; then
                destination=$line_end_found
            elif test -d "$line_found"; then
                destination=$line_found
            else
                destination=$path_argument
            fi

            builtin cd "$destination"
        fi
    else
        # If no arguments (or only options) was passed to cd, just run cd with the options (just in case the options -L or -P is set)
        builtin cd "$@"
    fi

    # Add current path to history only if does not exist in history file
    pwd_history=`grep -x "$PWD" ~/.autoleap.history | head -n1`
    if [ "$pwd_history" = "" ]; then
        echo $PWD >> ~/.autoleap.history
    fi
}
