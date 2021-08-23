.PHONY: build test clean update_submodules upgrade bootstrap-all bootstrap-min bootstrap-link
.DEFAULT_GOAL := help

CONTAINERS := $(shell docker ps -aq --filter "label=type=dotfiles")
# Defaults value to master branch
BRANCH ?= master
SHA := $(shell curl -s 'https://api.github.com/repos/dmorand17/bootstrappah/git/refs/heads/$(BRANCH)' | jq -r '.object.sha')
DATE := $(shell date +"%Y%m%d-%H%M")
backup_dir := $(wildcard ${HOME}/bootstrap-${DATE}.old)

build: ## Build dotfiles container. [BRANCH]=branch to build (defaults to 'master')
	@echo "gitsha1 -> $(SHA)"
ifeq ($(SHA),null)
	$(error SHA is not set.  Please ensure that [$(BRANCH)] exists)
endif
	docker build --file test/Dockerfile --build-arg BRANCH=$(BRANCH) --build-arg SHA=$(SHA) -t bootstrappah:latest .

test: ## Test dotfiles using docker
	docker run -e LANG="en_US.UTF-8" -e LANGUAGE="en_US.UTF-8" --label type=dotfiles -it bootstrappah /bin/bash

clean: ## Clean dotfiles docker containers/images
ifneq ($(CONTAINERS),)
	@echo "Removing containers: $(CONTAINERS)"
	docker rm $(CONTAINERS)
	docker image prune -f
else
	@echo "Nothing to clean..."
endif

update_submodules: ## Update submodules
	@echo "Updating submodules..."
	git submodule update --recursive

upgrade: ## Update the local repository, and run any updates
	@echo "Updating..."
	zplug update
	update_submodules

bootstrap-all: ## Bootstrap system (install/configure apps, link dotfiles)
	@echo "Bootstrapping system..."
	sudo ./bootstrap-init
	sudo ./bootstrap-zsh

bootstrap-min: ## Bootstrap minimum necessary (vim, profile, aliases)
	@echo "Bootstrapping minimum configuration..."
	ln -fs shell/.aliases ${HOME}/.aliases
	ln -fs shell/.profile ${HOME}/.profile

bootstrap-link:
	@echo "Linking files"
	$(foreach file, $(wildcard $(CURDIR)/configs/dotfiles/*), echo $(file); ln -fs $(file) $(HOME))

bootstrap-backup: | $(backup_dir)
	@echo "Continuation regardless of existence of $(backup_dir)"

$(backup_dir):
	@echo "Folder $(backup_dir) does not exist"
	mkdir $@

# Automatically build a help menu
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "; printf "\033[31m\nHelp Commands\033[0m\n--------------------------------\n"}; {printf "\033[32m%-22s\033[0m %s\n", $$1, $$2}'

