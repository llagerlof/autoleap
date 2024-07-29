# autoleap.sh
#
# Autoleap is a bash script that improves the `cd` command, allowing quick access to previously accessed directories.
#
# Version: 1.0.11
# Author:  Lawrence Lagerlof <llagerlof@gmail.com>
# GitHub:  http://github.com/llagerlof/autoleap
# License: https://opensource.org/licenses/MIT

cd () {

    local path_argument path_found path_dirname_found path_end_found path_any_found destination pwd_history dir_count index_found best_match history_contents

    # Initialize the history file
    if [ ! -f ~/.autoleap.history ]; then
        touch ~/.autoleap.history
    fi

    # Extract the directory path from the arguments
    path_argument=""
    for arg in "$@"; do
        if [ $arg != "-" ] && [ $arg != "--" ] && [ $arg != "-L" ] && [ $arg != "-P" ]; then
            path_argument=$arg
        fi
    done

    # If directory exists attempts to access it (or just run `cd` to go to home directory)
    if [ -d "$path_argument" ] || [ -z "$path_argument" ]; then
        builtin cd "$@"
    else
        # The actual search in history file only happens if a valid path argument was found
        if [ "$path_argument" != "" ]; then

            # Search for the directory in history file
            history_contents=`tac ~/.autoleap.history`
            path_dirname_found=`echo "$history_contents" | grep "/$path_argument$" | head -n1`
            path_end_found=`echo "$history_contents" | grep "$path_argument$" | head -n1`
            path_any_found=`echo "$history_contents" | grep "$path_argument" | head -n1`

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
            for i in $(seq $dir_count -1 0); do
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
            if [ "$destination" == "" ]; then
                destination=$path_found
            fi

            if [ -n "$destination" ] && [ ! -d "$destination" ]; then
                sed -i "\:^$destination$:d" ~/.autoleap.history
                echo "Directory \"$destination\" does not exist. Path removed from ~/.autoleap.history"
            elif [ -n "$destination" ]; then
                builtin cd "$destination"
            else
                builtin cd "$path_argument"
            fi
        fi
    fi

    # Add current path to history only if does not exist in history file
    pwd_history=`grep -x "$PWD" ~/.autoleap.history | head -n1`
    if [ "$pwd_history" == "" ]; then
        echo $PWD >> ~/.autoleap.history
    fi
}
