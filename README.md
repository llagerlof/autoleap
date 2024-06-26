# Autoleap

Access any previously visited directory typing `cd <part_of_path>`


## How to use it

After using the `cd` command several times, you will have a set of directories that you can easily access like bookmarks. For example:

You accessed the `/home/user/Downloads/` once. Next time you want to visit the `/Downloads` directory you can just type `cd Downloads` anywhere, or even `cd Dow`, for instance.

![demonstration](https://user-images.githubusercontent.com/193798/213001660-0eea41ef-a0be-46eb-98b6-6740b3957c02.png)


## How it works

When you access any directory using the `cd` command, the full path is stored into the `~/.autoleap.history` file.

When you type any string after the `cd` command, the script will try to change to the directory you've specified. If the directory does not exist, the script will search the history file for that string and change to the path if it is found in the history file.

All of this is possible because the script declares a `cd` function that wraps the built-in `cd` command.


## Installation

- Be sure you use the bash shell, since this script was written for it.
- Download the script `autoleap.sh` anywhere, for example, to `/usr/local/bin/`.
- `source` the script on your `.bashrc` (add the line `source /usr/local/bin/autoleap.sh` to the end of your `.bashrc`)
- Reopen the terminal (or source `.bashrc`)


## Acknowledgment

This project was inspired by [wting/autojump](https://github.com/wting/autojump).
