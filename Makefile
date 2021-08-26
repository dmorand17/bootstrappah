.DEFAULT_GOAL := help
BOOTSTRAP_CFG_DIR = $(CURDIR)/.bootstrap

DATE = $(shell date +"%Y%m%d")
backup_dir = ${HOME}/home-${DATE}.old
# HOMEFILES contains all files from config/dotfiles (e.g. .aliases, .functions, .inputrc)
HOMEFILES := $(shell ls -A config/dotfiles)
# DOTFILES is a list of resulting linked file (e.g. $(HOME)/.aliases)
DOTFILES := $(addprefix $(HOME)/,$(HOMEFILES))

upgrade: update_submodules ## Update the local repository, and run any updates
	@echo "Upgrading..."
	git pull origin master
	zplug update

update-submodules: ## Update submodules
	@echo "Updating submodules..."
	git submodule update --init --recursive
	git submodule update --recursive

backup: | $(backup_dir) ## Backup dotfiles
#	@echo "Continuation regardless of existence of $(backup_dir)"
	@echo "Backing up dotfiles..."
	@find ${HOME} -maxdepth 1 -name ".[^.]*" -type f -exec echo "backing up {} ..." \; -exec cp -rf "{}" ${backup_dir} \;
	@printf "\033[32mBackup complete...\033[0m\n\n"

$(backup_dir):
	@echo "Folder $(backup_dir) does not exist"
	@mkdir $@

mv-profile:
	@if [ ! -h ${HOME}/.profile ]; then \
		echo "Moving ${HOME}/.profile to ${HOME}/.profile.old" ; \
		mv ${HOME}/.profile ${HOME}/.profile.old ; \
	fi

$(HOME)/.profile.old: $(HOME)/.profile
	@echo "Moving ${HOME}/.profile to ${HOME}/.profile.old"
	@mv ${HOME}/.profile ${HOME}/.profile.old

link: backup mv-profile | $(DOTFILES) ## Link dotfiles
	@printf "\033[32mdotfiles linked...\033[0m\n\n"

# This will link all of our dotfiles into our home directory.
# This will NOT link any existing files
# $(CURDIR)/config/dotfiles/$(notdir $@)
# 	notdir $@ is grabbing just the filename (not directory) and appending it to a different path (e.g. $(CURDIR)/config/dotfiles)
$(DOTFILES):
	@ln -sv "$(CURDIR)/config/dotfiles/$(notdir $@)" $@

# Runs init job using order-only prequisite
# Once job is run once the .bootstrap/init file will be created and init job will no longer run
# Re-trigger by removing .bootsrap/init
install-packages: | $(BOOTSTRAP_CFG_DIR)/init bootstrap-zsh install-dircolors ## Initialize linux system (install git, ssh, fzf, etc)
$(BOOTSTRAP_CFG_DIR)/init: install-brew
ifeq ($(UNAME),Darwin)
	sh ./brew.sh
else
	@sudo add-apt-repository ppa:deadsnakes/ppa -y > /dev/null
	@sudo apt-get update -qq > /dev/null
	@sudo apt-get install -qq \
		build-essential \
		curl \
		git \
		vim \
        fzf \
        zsh \
		rsync \
        python3.9 \
		python3-pip \
        ripgrep \
		ssh > /dev/null
	@sudo pip3 install virtualenvwrapper -qq > /dev/null
endif
#sudo ./bootstrap-init
	touch $(BOOTSTRAP_CFG_DIR)/init
	@printf "\033[32mPackages installed...\033[0m\n\n"

install-brew: /home/linuxbrew/.linuxbrew/bin/brew
/home/linuxbrew/.linuxbrew/bin/brew: ## Install brew
# Install brew
	@if [ ! `command -v brew` ]; then \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash ; \
		printf "\033[32mBrew installed...\033[0m\n" ; \
		printf "\033[32mBrew configured...\033[0m\n\n" ; \
	else \
		printf "\033[31mBrew already installed!\033[0m\n\n" ; \
	fi

install-bat: install-brew ## Install bat (cat with wings)
ifneq ($(UNAME),Darwin)
	brew install bat
	printf "\033[32mBat installed...\033[0m\n\n"
endif

install-starship: install-brew | $(HOME)/.config## Install starship
	@if [ -n `which starship` ]; then \
		echo "Installing starship..." ; \
		brew install starship ;\
		cp config/starship/starship.toml ${HOME}/.config ; \
		echo 'eval "$(starship init zsh)"' >> ~/.zshrc ; \
		printf "\033[32mstarship installed...\033[0m\n\n" ; \
	else \
		printf "\033[31mstarship already installed...\033[0m\n\n" ; \
	fi

$(HOME)/.config:
	@echo "Folder $(HOME)/.config does not exist"
	mkdir -p $@

bootstrap-zsh: $(HOME)/.zshrc $(HOME)/.zplug.zsh ## Install ZSH and oh-my-zsh
$(HOME)/.zshrc:
# Download oh-my-zsh
	@curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -o install-oh-my-zsh.sh;
	@rm -rf ${HOME}/.oh-my-zsh
	@sh install-oh-my-zsh.sh --unattended
	@rm install-oh-my-zsh.sh
# Change shell to zsh
	@sudo chsh -s /usr/bin/zsh
# Update DEFAULT_USER if one exists
	@if ! grep -q DEFAULT_USER ${HOME}/.zshrc ; then \
		echo "Updating DEAFULT_USER in .zshrc ..." ; \
		echo "export DEFAULT_USER=`whoami`" >> ${HOME}/.zshrc ; \
	fi
	@echo '[[ -f "${HOME}/.profile" ]] && source ${HOME}/.profile' >> ${HOME}/.zshrc
	@printf "\033[32mzsh installed...\033[0m\n\n"

$(HOME)/.zplug.zsh:
# Install zplug
	@rm -rf ~/.zplug
	@curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh -o install-zplug;
	@zsh install-zplug
	@rm install-zplug
	@ln -fs $(CURDIR)/config/zplug/.zplug.zsh ${HOME}/.zplug.zsh
	@echo "[ -f ~/.zplug.zsh ] && source ~/.zplug.zsh" >> ${HOME}/.zshrc
	@chmod -R g-w,o-w ~/.oh-my-zsh/custom/plugins/
	@printf "\033[32mzplug installed...\033[0m\n\n"

install-robotomono: ${HOME}/RobotoMono.zip
${HOME}/RobotoMono.zip:
	@echo "Downloading RobotMono v.2.1.0..."
	@curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip --output ${HOME}/RobotoMono.zip
	@printf "\033[32mrobotomono downloaded to ${HOME}/RobotoMono.zip ...\033[0m\n\n"

install-dircolors:
	@ln -fs $(CURDIR)/plugins/dircolors-solarized ${HOME}/dircolors-solarized

bootstrap-ssh: ## Bootstrapping SSH
	@printf "\033[32mBootstrapping ssh for github...\033[0m\n"
ifeq ("$(wildcard ${HOME}/.ssh)","")
	@mkdir $(HOME)/.ssh && chmod 700 ~/.ssh
	@cp config/ssh/config ~/.ssh/config
	@touch ${HOME}/.ssh/authorized_keys && chmod 600 ${HOME}/.ssh/authorized_keys
	@chmod 644 ~/.ssh/config
	@ssh-keygen -t rsa -b 4096 && printf "\n\n\033[32mPublic key (add to github)\033[0m\n" && cat ~/.ssh/id_rsa.pub
	@chmod 600 ~/.ssh/id_rsa
	@ln -fs $(CURDIR)/config/ssh/.ssh-agent $(HOME)/.ssh-agent
	@printf "\033[32mssh bootstrapped...\033[0m\n\n"
else
	@printf "\033[31m${HOME}/.ssh already exists... \033[0m\n"
endif

bootstrap-vim: ## Installing VIM plugins
ifeq ("$(wildcard ${HOME}/.vim/autoload/plug.vim)","")
	@echo "Bootstrapping vim..."
	@curl -fLo $(HOME)/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@ln -fs $(CURDIR)/config/vim/.vimrc $(HOME)/.vimrc
	@mkdir $(HOME)/.vim/swaps
	@mkdir $(HOME)/.vim/backups
	@printf "\033[32mvim bootstrapped...\033[0m\n\n"
	@printf "\033[33mLaunch vi and run :PlugInstall to install plugins\033[0m\n\n"
else
	@printf "\033[31mvim already bootstrapped...\033[0m\n\n"
endif

bootstrap-min: ## Bootstrap minimum necessary - profile, aliases
	@echo "Bootstrapping minimum configuration..."
	ln -fs config/dotfiles/.aliases ${HOME}/.aliases
	ln -fs config/dotfiles/.profile ${HOME}/.profile
	@printf "\033[32mBootstrap min complete...\033[0m\n\n"

## Safe to re-run
getting-started: backup update-submodules link install-packages ## Run backups, link dotfiles, and install essential applications (curl, git, jq, etc)
	@printf "\033[1;33mGetting started completed\033[0m\n\n"
ifneq ($(UNAME),Darwin)
	@echo 'eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ${HOME}/.zshrc
endif
	@printf "\033[1;33mLaunch `zsh` to continue\033[0m\n\n"

install-and-bootstrap: install-bat bootstrap-apps ## Install and bootstrap system

install-optional:  install-starship install-robotomono ## Install optional apps (starship, robotomono)
	@printf "\033[1;33mInstalling apps completed\033[0m\n\n"
bootstrap-apps: bootstrap-ssh bootstrap-vim
	@printf "\033[1;33mBootstrapping completed\033[0m\n\n"

# Automatically build a help menu
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "; printf "\033[31m\nHelp Commands\033[0m\n--------------------------------\n"}; {printf "\033[32m%-22s\033[0m %s\n", $$1, $$2}'

.PHONY: all backup link bootstrap-min install-and-bootstrap install-optional bootstrap-apps install-packages install-brew bootstrap-zsh install-bat profile-link bootstrap-ssh bootstrap-vim install-robotomono install-dircolors install-starship update_submodules upgrade all bootstrap-robotomono
