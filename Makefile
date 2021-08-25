.PHONY: docker-build docker-test docker-clean update_submodules upgrade
.DEFAULT_GOAL := help
BOOTSTRAP_CFG_DIR = $(CURDIR)/.bootstrap

CONTAINERS = $(shell which docker && docker ps -aq --filter "label=type=dotfiles")
# Defaults value to master branch
BRANCH ?= master
SHA := $(shell curl -s 'https://api.github.com/repos/dmorand17/bootstrappah/git/refs/heads/$(BRANCH)' | jq -r '.object.sha')
DATE = $(shell date +"%Y%m%d")
backup_dir = ${HOME}/home-${DATE}.old

#### START DOCKER SECTION
RECENT_BUILD_BRANCH_SHA = $(shell cat .bootstrap/docker 2>/dev/null)
BRANCH_SHA = $(BRANCH):$(SHA)

docker-test: docker-build ## Test dotfiles using docker
	docker run -e LANG="en_US.UTF-8" -e LANGUAGE="en_US.UTF-8" --label type=dotfiles -it bootstrappah /bin/bash

docker-build: ## Build dotfiles container. [BRANCH]=branch to build (defaults to 'master')
	@echo "Current build: $(RECENT_BUILD_BRANCH_SHA)"
	@echo "Requested build: $(BRANCH_SHA)"
ifeq ($(SHA),null)
	$(error SHA is not set.  Please ensure that [$(BRANCH)] exists, and has been pushed to remote.  Other failures could be related to API Rate limit)
endif
ifneq ($(RECENT_BUILD_BRANCH_SHA),$(BRANCH_SHA))
	docker build --file test/Dockerfile --build-arg BRANCH=$(BRANCH) --build-arg SHA=$(SHA) -t bootstrappah:latest .
	@echo "Writing $(BRANCH_SHA) to $(CURDIR)/.bootstrap/docker"
	@echo "$(BRANCH_SHA)" > $(CURDIR)/.bootstrap/docker
else
	@echo "Docker does not need to be built"
endif

docker-clean: ## Clean dotfiles docker containers/images
ifneq ($(CONTAINERS),)
	@echo "Removing containers: $(CONTAINERS)"
	docker rm $(CONTAINERS)
	docker image prune -f
else
	@echo "Nothing to clean..."
endif
#### END DOCKER SECTION

update-submodules: ## Update submodules
	@echo "Updating submodules..."
	git submodule update --init --recursive
	git submodule update --recursive

upgrade: ## Update the local repository, and run any updates
	@echo "Updating..."
	zplug update
	update_submodules

.PHONY: bootstrap-backup init zsh link all bootstrap-min bootstrap-ssh bootstrap-vim bootstrap-robotomono bootstrap-starship bootstrap-homebrew

bootstrap-backup: | $(backup_dir) ## Backup dotfiles
	@echo "Continuation regardless of existence of $(backup_dir)"
	@echo "Backing up dotfiles..."
	@find ${HOME} -maxdepth 1 -name ".[^.]*" -type f -exec echo "backing up {} ..." \; -exec cp -rf "{}" ${backup_dir} \;

$(backup_dir):
	@echo "Folder $(backup_dir) does not exist"
	@mkdir $@

bootstrap-min: ## Bootstrap minimum necessary - profile, aliases
	@echo "Bootstrapping minimum configuration..."
	ln -fs config/dotfiles/.aliases ${HOME}/.aliases
	ln -fs config/dotfiles/.profile ${HOME}/.profile

# Runs init job using order-only prequisite
# Once job is run once the .bootstrap/init file will be created and init job will no longer run
# Re-trigger by removing .bootsrap/init
init: | $(BOOTSTRAP_CFG_DIR)/init ## Initialize linux system (install git, ssh, fzf, etc)
$(BOOTSTRAP_CFG_DIR)/init:
	sudo ./bootstrap-init
	touch $(BOOTSTRAP_CFG_DIR)/init

zsh: $(HOME)/.zshrc $(HOME)/.zplug.zsh ## Install ZSH and oh-my-zsh
$(HOME)/.zshrc:
# Download oh-my-zsh
	curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -o install-oh-my-zsh.sh;
	sh install-oh-my-zsh.sh
	rm install-oh-my-zsh.sh
# Change shell to zsh
	sudo chsh -s /usr/bin/zsh
# Update DEFAULT_USER if one exists
	@if ! grep -q DEFAULT_USER $HOME/.zshrc ; then \
		echo "Updating DEAFULT_USER in .zshrc ..." ; \
		echo "export DEFAULT_USER=`whoami`" >> $HOME/.zshrc ; \
	fi

$(HOME)/.zplug.zsh:
# Install zplug
	@curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh -o install-zplug;
	@zsh install-zplug
	@rm install-zplug
	@ln -fs $(CURDIR)/config/zplug/.zplug.zsh $HOME/.zplug.zsh
	@echo "[ -f ~/.zplug.zsh ] && source ~/.zplug.zsh" >> $HOME/.zshrc
	@chmod -R g-w,o-w ~/.oh-my-zsh/custom/plugins/

# HOMEFILES contains all files from config/dotfiles (e.g. .aliases, .functions, .inputrc)
HOMEFILES := $(shell ls -A config/dotfiles) 
# DOTFILES is a list of resulting linked file (e.g. $(HOME)/.aliases)
DOTFILES := $(addprefix $(HOME)/,$(HOMEFILES))

# This ensures that the .profile file will be renamed prior to any links
profile-link: $(HOME)/.profile.old link
$(HOME)/.profile.old: $(HOME)/.profile
	@echo "Moving ${HOME}.profile to ${HOME}.profile.old"
	@mv ${HOME}/.profile ${HOME}/.profile.old

link: | $(DOTFILES) ## Link all files from config/dotfiles
# This will link all of our dotfiles into our home directory.  
# This will NOT link any existing files
# $(CURDIR)/config/dotfiles/$(notdir $@)
# 	notdir $@ is grabbing just the filename (not directory) and appending it to a different path (e.g. $(CURDIR)/config/dotfiles) 
$(DOTFILES):
	@ln -sv "$(CURDIR)/config/dotfiles/$(notdir $@)" $@

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
else
	@printf "\033[31mSSH Directory already exists... \033[0m\n"
endif

bootstrap-vim: ## Installing VIM plugins
ifeq ("$(wildcard ${HOME}/.vim/autoload/plug.vim)","")
	@echo "Bootstrapping vim..."
	@curl -fLo $(HOME)/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@ln -fs $(CURDIR)/config/vim/.vimrc $(HOME)/.vimrc
	@mkdir $(HOME)/.vim/swaps
	@mkdir $(HOME)/.vim/backups
	@echo "Installation complete!  Launch vi and run :PlugInstall to install plugins"
else
	@echo "vim-plug already installed..."
endif

bootstrap-robotomono: ${HOME}/RobotoMono.zip
${HOME}/RobotoMono.zip: 
	@echo "Downloading RobotMono v.2.1.0..."
	@curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip --output ${HOME}/RobotoMono.zip

bootstrap-starship: ## Install starship
	@if [ -n `which starship` ]; then ./bootstrap-starship; fi

bootstrap-homebrew: ## install linux homebrew (optional)
	@if [ -n `which brew` ]; then \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash ; \
		echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/dotuser/.profile ; \
    	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" ; \
	fi

all: bootstrap-backup init zsh profile-link | bootstrap-ssh bootstrap-vim bootstrap-robotomono bootstrap-starship ## Bootstrap system (install/configure apps, link dotfiles)
	@echo "Bootstrapping system completed!"

# Automatically build a help menu
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "; printf "\033[31m\nHelp Commands\033[0m\n--------------------------------\n"}; {printf "\033[32m%-22s\033[0m %s\n", $$1, $$2}'

