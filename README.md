# Autoleap

Access any previously visited directory typing `cd <part_of_path>`


## How to use it

After using the `cd` command several times, you will have a set of directories that you can easily access like bookmarks. For example:

You accessed the `/home/user/Downloads/` once. Next time you want to visit the `/Downloads` directory you can just type `cd Downloads` anywhere, or even `cd Dow`, for instance.

![demonstration](https://user-images.githubusercontent.com/193798/213001660-0eea41ef-a0be-46eb-98b6-6740b3957c02.png)


## How it works

The script declares a `cd` function that wraps the built-in `cd` command. Every time you change directories, the full path is stored into the `~/.autoleap.history` file.

The built-in `cd` is **always tried first**, so all standard behavior is fully preserved — including `CDPATH`, `cd -`, `cd old new` substitution, and options like `-P`/`-L`. Autoleap only kicks in as a fallback when the built-in `cd` cannot resolve the path on its own.

When the fallback activates, Autoleap searches the history file for your input and changes to the best matching path. If there are multiple matches, Autoleap will use `fzf` (if available) to display an interactive selection menu. In this list, exact final-directory-name matches are prioritized over broader substring-only matches, and the displayed order preserves this ranking.

Paths that no longer exist on disk are automatically removed from the history file when encountered.


## Installation

- Be sure you use the bash shell, since this script was written for it.
- Download the script `autoleap.sh` anywhere, for example, to `/usr/local/bin/`.
- `source` the script on your `.bashrc` (add the line `source /usr/local/bin/autoleap.sh` to the end of your `.bashrc`)
- Reopen the terminal (or source `.bashrc`)
- For interactive directory selection, install `fzf` by following the instructions at https://github.com/junegunn/fzf/


## Acknowledgment

This project was inspired by [wting/autojump](https://github.com/wting/autojump).
