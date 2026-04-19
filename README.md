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

- Be sure you use the Bash shell, since this script was written for it.
- Autoleap works by being **sourced** from your `~/.bashrc`; simply placing it on `PATH` is not enough.
- Reopen the terminal after installing, or run `source ~/.bashrc`.
- For interactive directory selection, install `fzf` by following the instructions at https://github.com/junegunn/fzf/

### Install only for the current user

#### Option 1: Clone the repository and symlink the script into `~/.local/bin`

```bash
mkdir -p ~/repos ~/.local/bin
git clone https://github.com/llagerlof/autoleap.git ~/repos/autoleap
chmod +x ~/repos/autoleap/autoleap.sh
ln -sf ~/repos/autoleap/autoleap.sh ~/.local/bin/autoleap.sh
grep -qxF 'source "$HOME/.local/bin/autoleap.sh"' ~/.bashrc || echo 'source "$HOME/.local/bin/autoleap.sh"' >> ~/.bashrc
```

If you prefer `~/repositories`, replace `~/repos` with `~/repositories`.

#### Option 2: Download the script directly into `~/.local/bin`

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/llagerlof/autoleap/HEAD/autoleap.sh -o ~/.local/bin/autoleap.sh
chmod +x ~/.local/bin/autoleap.sh
grep -qxF 'source "$HOME/.local/bin/autoleap.sh"' ~/.bashrc || echo 'source "$HOME/.local/bin/autoleap.sh"' >> ~/.bashrc
```

### Install for everyone

#### Option 3: Clone the repository and symlink the script into `/usr/local/bin`

Clone the repository into a normal user's home directory, then create the system-wide symlink with `sudo`:

```bash
mkdir -p ~/repos
git clone https://github.com/llagerlof/autoleap.git ~/repos/autoleap
chmod +x ~/repos/autoleap/autoleap.sh
sudo ln -sf ~/repos/autoleap/autoleap.sh /usr/local/bin/autoleap.sh
grep -qxF 'source /usr/local/bin/autoleap.sh' ~/.bashrc || echo 'source /usr/local/bin/autoleap.sh' >> ~/.bashrc
```

If you prefer `~/repositories`, replace `~/repos` with `~/repositories`.

This setup works best when other users can read the cloned repository location. If you do not want to grant other users access through one user's home directory, use Option 4 instead.

#### Option 4: Download the script directly into `/usr/local/bin`

```bash
sudo curl -fsSL https://raw.githubusercontent.com/llagerlof/autoleap/HEAD/autoleap.sh -o /usr/local/bin/autoleap.sh
sudo chmod +x /usr/local/bin/autoleap.sh
grep -qxF 'source /usr/local/bin/autoleap.sh' ~/.bashrc || echo 'source /usr/local/bin/autoleap.sh' >> ~/.bashrc
```


## Acknowledgment

This project was inspired by [wting/autojump](https://github.com/wting/autojump).
