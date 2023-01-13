# autoleap.sh

Access any previously visited directory typing `cd part_of_path`. Currently only works on `bash`. 


## Installation

- Download the script `autojump.sh` anywhere.
- `source` the script on your `.bashrc` (add the line `source /path/to/script/autoleap.sh` to the end of your `.bashrc`)
- Reopen the terminal (or source `.bashrc`)


## How it works

When you access any directory using the `cd` command, the full path is stored into the `~/.autoleap.history` file.

When you type any string after the cd command you will access the directory you choose, but if the directory path does not exist, it searchs the history file for that string and access the path, if found in history file.

All of this is possible because the script declares a `cd` function that uses the built-in `cd` command, but implements new functionalities.


## How to use it

After using some times the `cd` command, you will have a set of "bookmarks" that you can access easily. For example:

You accessed the `/home/user/Downloads/` once. Next time you want to visit the `/Downloads` directory you can just type `cd Downloads` anywhere, or even `cd Dow`, for instance.


## Acknowledgment

This project was inspired by [wting/autojump](https://github.com/wting/autojump).
