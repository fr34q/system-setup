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

is_cmd () {
    command -v $@ &>/dev/null
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

comment "Install git to get access to the real stuff"
cond_exec yay -S git

comment "Copy and personalize configuration for git"
setup_git () {
    GITCFG="$HOME/.gitconfig"
    cp cfg/.gitconfig $GITCFG
    echo -n "Your name for global git config: " && read GITNAME
    sed -i "s/<GITNAME>/$GITNAME/g" "$GITCFG"
    echo -n "Your e-mail for global git config: " && read GITEMAIL
    sed -i "s/<GITEMAIL>/$GITEMAIL/g" "$GITCFG"
}
cond_exec setup_git

comment "Install system utility tools"
cond_exec yay -S net-tools htop xclip

comment "Install tools for the terminal"
cond_exec yay -S screen kitty hstr-git oh-my-zsh-git powerline-fonts-git xcwd-git

if is_cmd zsh && is_cmd kitty; then
    comment "Set zsh as default shell and configure kitty"
    setup_shell () {
        cp cfg/.zshrc "$HOME/"
        mkdir -p "$HOME/.config/kitty"
        cp cfg/kitty.conf "$HOME/.config/kitty/"
        chsh $(which zsh)
    }
    cond_exec setup_shell
fi

comment "Install user scripts to ~/bin"
cond_exec git clone git@github.com:fr34q/personal-bin.git ~/bin

comment "Install personalizations for i3 window manager"
cond_exec yay -S betterlockscreen i3blocks

comment "Install configuration for i3 window manager"
cond_exec git clone --recurse-submodules git@github.com:fr34q/i3-config.git $HOME/.config/i3

comment "Enable lockscreen after closing the laptop lid"
setup_lockscreen () {
    LOCKSCREENUSER=$(id -u -n)
    LOCKSCREENPATH=$(echo "$HOME/bin/lockscreen" | sed 's_/_\\/_g')
    cp svc/lockscreen.service /tmp/lockscreen.service
    sed -i "s/<LOCKSCREENUSER>/$LOCKSCREENUSER/g" /tmp/lockscreen.service
    sed -i "s/<LOCKSCREENPATH>/$LOCKSCREENPATH/g" /tmp/lockscreen.service
    sudo cp /tmp/lockscreen.service /etc/systemd/system/
    sudo systemctl enable lockscreen
}
cond_exec setup_lockscreen

comment "Install text/code editors"
cond_exec yay -S vim gedit code

if is_cmd code; then
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


# Python stuff
yay -S python-pip python2-pip
pip2 install --user bpython
pip install --user bpython

# Password manager
yay -S keepass

# Office
yay -S firefox thunderbird thunderbird-i18n-de libreoffice-fresh libreoffice-fresh-de foxitreader

# Latex
yay -S texlive-most biber texlive-localmanager-git
code --install-extension James-Yu.latex-workshop
# For minted package (code highlighting)
yay -S python-pygments pygmentize

# Communication
yay -S rambox telegram-desktop skypeforlinux-preview-bin

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


# Set default applications
# TODO Replace or extend ~/.config/mimeapps.list

# Setup KIT VPN connection
# TODO Include KIT.ovpn
nmcli connection import type openvpn file KIT.ovpn
echo -n "Your KIT username for VPN: " && read KITUSER
nmcli connection modify KIT vpn.user-name $KITUSER

# .config/mimeapps.list