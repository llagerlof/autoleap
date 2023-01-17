# Autoleap

Access any previously visited directory typing `cd part_of_path`


## How to use it

After using some times the `cd` command, you will have a set of "bookmarks" that you can access easily. For example:

You accessed the `/home/user/Downloads/` once. Next time you want to visit the `/Downloads` directory you can just type `cd Downloads` anywhere, or even `cd Dow`, for instance.

![demonstration](https://user-images.githubusercontent.com/193798/213001660-0eea41ef-a0be-46eb-98b6-6740b3957c02.png)


## How it works

When you access any directory using the `cd` command, the full path is stored into the `~/.autoleap.history` file.

When you type any string after the cd command you will access the directory you choose, but if the directory path does not exist, it searchs the history file for that string and access the path, if found in history file.

All of this is possible because the script declares a `cd` function that uses the built-in `cd` command, but implements new functionalities.



## Installation

- Be sure you use the bash shell, since this script was wrote for it.
- Download the script `autoleap.sh` anywhere.
- `source` the script on your `.bashrc` (add the line `source /path/to/script/autoleap.sh` to the end of your `.bashrc`)
- Reopen the terminal (or source `.bashrc`)


## Acknowledgment

This project was inspired by [wting/autojump](https://github.com/wting/autojump).
