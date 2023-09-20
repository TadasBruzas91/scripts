#!/usr/bin/env bash

function configuration {
        DOTFILES_REPO="https://github.com/TadasBruzas91/dotfiles.git"
        SHELL_CONFIG_COMMENT="# bashrc configured by setup-server.sh script"
}

PACKAGES=(
        git
        neovim
        ranger
        neofetch
        bpytop
        docker-ce
        docker-ce-cli
        containerd.io
        docker-buildx-plugin
        docker-compose-plugin
)

function line {
        printf "*%.0s" {1..15}
        printf "%s" "$1"
        printf "*%.0s" {1..15}
        printf "\n"
}

# Ask user if start script
read -p "Start setup?(y|n): " USER_ANSWER

# Check user answer
if [ "$USER_ANSWER" != "y" ]
then
	echo "Script do nothing"
	exit 0
fi

# Configure variables
configuration

# Update system
sudo echo " "
line "| Script started |"
echo " "
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y

# Configure docker
echo " "
line "| Configuring docker... |"
echo " "

DOCKER_KEYRING_DIR="/etc/apt/keyrings/docker.gpg"
if [ ! -f "$DOCKER_KEYRING_DIR" ]
then
        sudo apt install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        sudo echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
fi

NORMAL_USER="$(id -nu 1000)"
if [ "$NORMAL_USER" != "" ]; then
        # Add docker group to normal user
        echo " "
        line "| User exists $NORMAL_USER |"
        echo " "
        sudo groupadd docker
        sudo usermod -aG docker $NORMAL_USER

        # Configure .bashrc
        echo " "
        line "| Configure .bashrc |"
        echo " "

        BASHRC_PATH="/home/$NORMAL_USER/.bashrc"
        SHELL_CONFIG_PATH="/home/$NORMAL_USER/.shell-config.sh"
        IS_SHELL_CONFIG_LOADED="$(grep "$SHELL_CONFIG_COMMENT" $BASHRC_PATH | head -1)" # grep only first match

        if [ "$IS_SHELL_CONFIG_LOADED" != "$SHELL_CONFIG_COMMENT" ]
        then
                echo " " >> $BASHRC_PATH
                echo $SHELL_CONFIG_COMMENT >> $BASHRC_PATH
                echo "source $SHELL_CONFIG_PATH" >> $BASHRC_PATH # Add import .shell-config.sh to .bashrc
                echo " " >> $BASHRC_PATH
        fi
fi

# Install packages specified in PACKAGES list
echo " "
line "| Install packages |"
echo " "
sudo apt install -y ${PACKAGES[@]}

# List installed packages
echo " "
line "| Installed packages |"
echo " "
apt list ${PACKAGES[@]} --installed

# Configure dotfiles
echo " "
line "| Configure dotfiles |"
echo " "

# Clone dotfiles repo
DOTFILES_DIR="/home/$NORMAL_USER/dotfiles"
if [ "$NORMAL_USER" != "" ] && [ ! -d "$DOTFILES_DIR" ]
then
        git clone --bare $DOTFILES_REPO $DOTFILES_DIR
fi

if [ -d "$DOTFILES_DIR" ]
then
        function config {
                git --git-dir="$DOTFILES_DIR" --work-tree="/home/$NORMAL_USER" "$@"
        }

        config config --local status.showUntrackedFiles no
        config fetch --all
        config reset --hard
else
        line "| Can't clone dotfiles from '$DOTFILES_REPO' repository!!! |"
fi

line "| Script ended |" "{" "}"
echo " "

line "| INFO Message |"
# Show message how docker is configured
if [ "$NORMAL_USER" != "" ]; then
	echo " "
	echo "Reboot system to use Docker with user $NORMAL_USER !!!"
        echo "Or logout and login back."
else
	echo "Docker can be used only with root user !!!"
fi

