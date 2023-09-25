#!/usr/bin/env bash

function configuration {
        DOTFILES_REPO="https://github.com/TadasBruzas91/dotfiles.git"
        SHELL_CONFIG_COMMENT="# bashrc configured by setup-server.sh script"
}

PACKAGES=(
        tree
        rsync
        git
        neovim
        ranger
        neofetch
        bpytop
        python3-certbot-dns-cloudflare
        python3-certbot-nginx
        certbot
        nginx
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

DOCKER_KEYRING_FILE="/etc/apt/keyrings/docker.gpg"
if [ ! -f "$DOCKER_KEYRING_FILE" ]
then
        echo " "
        line "| Configuring docker... |"
        echo " "

        sudo apt install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        sudo echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# Configure nginx

NGINX_KEYRING_FILE="/usr/share/keyrings/nginx-archive-keyring.gpg"
if [ ! -f "$NGINX_KEYRING_FILE" ]
then
        echo " "
        line "| Configuring nginx... |"
        echo " "

        sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
        curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
        echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx
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
sudo apt update
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

# Enable nginx startup on reboot
sudo systemctl enable nginx

# Install fail2ban from github
FAIL_TWO_BAN="$(apt list --installed 2> /dev/null | grep fail2ban)"
if [ "$FAIL_TWO_BAN" != "" ]
then
        echo " "
        line "| Install fail2ban from github |"
        echo " "
        cd /tmp
        wget https://github.com/fail2ban/fail2ban/releases/download/1.0.2/fail2ban_1.0.2-1.upstream1_all.deb -O fail2ban.deb
        sudo dpkg -i fail2ban.deb
fi

# Configure home bare git repository
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

