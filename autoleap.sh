# autoleap.sh
#
# Autoleap is a bash script that improves the `cd` command, allowing quick access to previously accessed directories.
#
# Version: 1.0.4
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

            # Search for the directory in history file
            path_dirname_found=`tac ~/.autoleap.history | grep "\/$path_argument$" | head -n1`
            path_end_found=`tac ~/.autoleap.history | grep "$path_argument$" | head -n1`
            path_any_found=`tac ~/.autoleap.history | grep "$path_argument" | head -n1`

            # Set the best path found
            if [ "$path_dirname_found" != "" ]; then
                path_found=$path_dirname_found
            elif [ "$path_end_found" != "" ]; then
                path_found=$path_end_found
            else
                path_found=$path_any_found
            fi

            # Create an array containing all directories names in path_found for easier parsing
            IFS='/' read -ra path_found_parts <<< "$path_found"
            dir_count=${#path_found_parts[@]}

            # Search for a best match in all directory names of the path
            for i in $(seq $dir_count -1 0)
            do
                if [[ ${path_found_parts[i]} == "$path_argument" ]]; then
                    index_found=$i
                    break
                elif [[ ${path_found_parts[i]} == *"$path_argument"* ]]; then
                    index_found=$i
                    break
                fi
            done

            # Remove from array the directories after the best matched directory. This is our destination.
            best_match=( "${path_found_parts[@]:0:$index_found + 1}" )
            destination=$(IFS='/'; echo "${best_match[*]}")
            if [ "$destination" = "" ]; then
                destination=$path_found
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
    unset path_found
    unset path_dirname_found
    unset path_end_found
    unset path_any_found
    unset destination
    unset pwd_history
    unset dir_count
    unset index_found
    unset best_match
}
