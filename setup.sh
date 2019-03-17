#!/bin/sh
# This script relies on a fresh Manjaro installation with i3wm

bold () {
    echo -n "$(tput bold)$@$(tput sgr0)"
}
red () {
    echo -n "$(tput setaf 1)$@$(tput sgr0)"
}
green () {
    echo -n "$(tput setaf 2)$@$(tput sgr0)"
}

COMMENT_IDX=1
comment () {
    echo -en "\n$(red "$COMMENT_IDX. >>>") $(bold "$@")\n"
    COMMENT_IDX=$((COMMENT_IDX+1))
}

cond_exec () {
    echo "> $(bold "Action: $@")"
    echo -n "  [(0) do (default), (1) skip, (2) abort] ?> " && read LINE
    if [ -z "$LINE" ] || [[ "$LINE" == "0" ]]; then
        "$@"
        echo $(green "Action completed.")
    elif [[ "$LINE" == "1" ]]; then
        echo $(green "Skipping this action.")
    else
        echo "$(red "Aborting the setup script.")"
        exit 1
    fi
}

echo "$(red "=== Installation script to setup a new Manjaro installation ===")"
echo "Press enter to continue. Script will be aborted if anything else is pressed."
echo -n "?> " && read LINE
if [[ ! -z "$LINE" ]]; then 
  echo "$(red "Non-empty input. Aborting.")"
  exit 1
fi

comment "Install yay to get access to the AUR"
cond_exec sudo pacman -S yay

comment "Updating all existing packages"
cond_exec yay -Syu

comment "Install system utility tools"
cond_exec yay -S net-tools htop

comment "Install tools for the terminal"
cond_exec yay -S screen kitty hstr-git oh-my-zsh-git powerline-fonts-git
# TODO: Set this up

comment "Install text/code editors"
cond_exec yay -S git vim gedit code

if command -v code; then
    # VS Code is installed -> can set it up

    install_code_extensions () {
        while read -r LINE; do
            echo $(green "Installing VS Code extension \"$LINE\"")
            code --install-extension $LINE
        done < "code-extensions.txt"
    }

    CONFIGDIR="$HOME/.config/Code - OSS/User"
    if [ -d "$CONFIGDIR" ]; then
        comment "Copy configuration for Visual Studio Code editor"
        cond_exec cp --backup=t "code-settings.json" "$CONFIGDIR/settings.json"
    fi
    
    comment "Install VS Code extensions"
    cond_exec install_code_extensions
fi

# Safety barrier for now
echo -e "\n$(red "=== Installation script completed without errors ===")"
exit 0

# own i3lock
yay -S betterlockscreen
# TODO: Setup that it is default option and will be used

# Python stuff
yay -S python-pip python2-pip
pip2 install --user bpython
pip install --user bpython

# Password manager
yay -S keepass

# Office
yay -S firefox thunderbird libreoffice-fresh libreoffice-fresh-de

# Latex
yay -S texlive-most biber texlive-localmanager-git
code --install-extension James-Yu.latex-workshop
# For minted package (code highlighting)
yay -S python-pygments pygmentize



# Communication
yay -S rambox telegram-desktop

# Multimedia editing
yay -S gimp inkscape audacity redshift

# Remote connections
yay -S vinagre


###
###   Configuration
###

# Disable "beep"
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# Copy user /bin folder
# TODO Copy

# Set default applications
# TODO Replace or extend ~/.config/mimeapps.list

# Customized i3 config
# TODO Replace ~/.i3/config

# User betterlockscreen as lockscreen
# TODO set in $(which blurlock) or in ~/.i3/config

# Set zsh as shell and configure kitty
# TODO Copy .Xdefaults und .zshrc
chsh $(which zsh)
# TODO Copy .config/kitty/kitty.conf

# Copy git config
# TODO .gitconfig

# Setup KIT VPN connection
# TODO Include KIT.ovpn
nmcli connection import type openvpn file KIT.ovpn
echo -n "Your KIT username for VPN: " && read KITUSER
nmcli connection modify KIT vpn.user-name $KITUSER

# .config/mimeapps.list