# Bootstrappah

Allows bootstrapping a system (vim, git, ssh, etc).

## Applications Bootstrapped

* [fzf](https://github.com/junegunn/fzf) command-line fuzzy finder
* [bat](https://github.com/sharkdp/bat) `cat` clone with syntax highlighting

### `zsh`

* [oh-my-zsh|https://ohmyz.sh/] zsh framework
* [antigen|https://github.com/zsh-users/antigen] zsh plugin manager

**plugins**
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions.git)
* [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting.git)

**themes**
* dracula (default)
* powerlevel10k

### `vim` plugins

Current list of VIM plugins which are installed via vim-plug plugin manager
* [vim-plug](https://github.com/junegunn/vim-plug)
* [nerdtree](https://github.com/preservim/nerdtree)
* [vim-airline](https://github.com/vim-airline/vim-airline)
** vim-airline-theme
* [vim-fugitive](https://github.com/tpope/vim-fugitive)
* [Conquer of Completion](https://github.com/neoclide/coc.nvim)

### `starship`
[starship](https://starship.rs/) _(optional)_ installed and bootstrapped.

## Getting Started

These instructions will give you a copy of the project up and running on
your local machine for bootstrapping a new system.

### Installing

1.  Clone repository
```bash
git clone https://github.com/dmorand17/bootstrappah.git && cd bootstrappah
```

### Dependencies

Requirements for the software and other tools to build, test and push
- None at this time

## Bootstrapping

Show useful examples of how the program can be used, screenshots, etc.

1.  Run `make getting-started` to perform necessary backups, and install essential apps (git, curl, jq, etc)
1.  Run `zsh` to launch zsh to continue bootstrapping
1.  Run `make install-and-bootstrap` to install and bootstrap applications
    * Configures the following apps:
        * ssh
        * vim

Output from `make help`
```
Help Commands
--------------------------------
backup                 Backup dotfiles
bootstrap-min          Bootstrap minimum necessary - profile, aliases
bootstrap-ssh          Bootstrapping SSH
bootstrap-vim          Installing VIM plugins
bootstrap-zsh          Install ZSH and oh-my-zsh
getting-started        Run backups, link dotfiles, and install essential applications (curl, git, jq, etc)
install-and-bootstrap  Install and bootstrap system
install-bat            Install bat (cat with wings)
install-packages       Initialize linux system (install git, ssh, fzf, etc)
install-starship       Install starship
link                   Link dotfiles
update-submodules      Update submodules
upgrade                Update the local repository, and run any updates
```
### Upgrade existing system

Run `make upgrade` to upgrade existing solution.  The following commands are executed:
```bash
zplug update
update_submodules
```

### Dotfile extension

**Shell**: Any linked shell configuration can be extended by creating a `.local` version (e.g. .alias.local)

Alternatively, to update while avoiding the confirmation prompt:

```bash
# Git credentials
# Not in the repository, to prevent people from accidentally committing under my name 
GIT_AUTHOR_NAME="John Doe"
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" 
git config --global user.name "$GIT_AUTHOR_NAME" 
GIT_AUTHOR_EMAIL="user@example.com"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL" 
git config --global user.email "$GIT_AUTHOR_EMAIL
```

### Optional Steps
add anything optional here
## Running Tests

A docker image can be created to be used to test.

| Command     | Description |
| ----------- | ----------- |
| `make -f Makefile-test test [BRANCH='branch']`| Build an image.  Default branch is `master` |
| `make -f Makefile-test clean`| clean any unused images/containers |

## Versioning

We use [Semantic Versioning](http://semver.org/) for versioning. For the versions
available, see the [tags on this
repository](https://github.com/dmorand17/{project}/tags).

### Version History

* 0.2
    * Various bug fixes and optimizations
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release

## Roadmap

- [ ] item 1

## License

This project is licensed under the [MIT](LICENSE.md) License.  

