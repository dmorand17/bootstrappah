for file in ~/.{aliases,functions}; do
	# if file has read permissions and exists then source file
	[ -r "$file" ] && [ -f "$file" ] && source "$file";

    # Allow for local version overrides
    local="${file}.local"
	[ -r "$local" ]  && [ -f "$local" ] && source "$local";
done;
unset file;

# Source git completion
if [ -f ~/.git-completion.bash ]; then
  source ~/.git-completion.bash
fi

# Source functions
if [ -d ~/.functions ]; then
	for F in ~/.functions/*; do
		source $F
	done
fi

### Get os name via uname ###
_myos="$(uname)"

### setup aliases, etc per os
case $_myos in
   Linux) 
    eval `dircolors -b ~/dircolors-solarized/dircolors.ansi-light`
	;;
   Darwin) 
    eval `gdircolors -b ~/dircolors-solarized/dircolors.ansi-light`
	alias ls="gls"
	;;
   *) ;;
esac

# virtualenvwrapper
export WORKON_HOME=$HOME/.virtualenvs   # Optional
export PROJECT_HOME=$HOME/development     # Optional
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
export VIRTUALENVWRAPPER_VIRTUALENV=/usr/local/bin/virtualenv
source /usr/local/bin/virtualenvwrapper.sh

# Source the ssh agent if found
if [ -f ~/.ssh-agent ]; then . ~/.ssh-agent; fi
