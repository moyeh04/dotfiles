# Dotfiles Management with GNU Stow

This repository contains my dotfiles, managed using [GNU Stow](https://www.gnu.org/software/stow/). Stow is a simple tool for managing symlinked configurations, making it easy to maintain and version-control dotfiles across multiple systems.

## Why Use Stow?

- Keeps configuration files organized in a single repository.
- Uses symlinks instead of manual copying, ensuring easy updates.

- Allows for simple management of different configurations across systems.

## Setting Up on a New System

If you're setting up your dotfiles on a new machine, follow these steps:

### 1. Install Stow

On Debian/Ubuntu:

```sh
sudo apt install stow
```

On Arch:

```sh
sudo pacman -S stow
```

Or using Homebrew:

```sh
brew install stow
```

On macOS (using Homebrew):

```sh
brew install stow
```

### 2. Clone the Repository

```sh
git clone https://github.com/moyeh04/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Stow Your Configurations

Move your configuration files into the dotfiles repository, maintaining the same parent hierarchy as the original locations. For example, if your config file was in `~/.config/nvim/init.vim`, place it in `dotfiles/.config/nvim/init.vim`.

Then, navigate to the dotfiles directory and run:

```sh
stow .
```

This will create symlinks for everything, preserving the parent/child structure.

### 4. Verify Symlinks

Check that your dotfiles are correctly linked in your home directory:

```sh
ls -la ~/
```

## Adding New Configurations

1. Place the configuration files in a directory inside your dotfiles repo, maintaining the original hierarchy. For example, `~/dotfiles/.zshrc` for `~/.zshrc`.
2. Run `stow .` to create the symlinks.

## Unstowing (Removing Symlinks)

If you need to remove a symlinked config:

```sh
stow -D .  # This will remove all symlinks created by Stow

```

**For more details, refer to the official documentation on the GNU Stow
website.**

## Keeping Your Dotfiles Updated

After making changes to your dotfiles, commit and push them to your repository:

```sh
git add .
git commit -m "Update dotfiles"
git push origin main
```

Now, your dotfiles are easy to manage and portable across different systems!
