#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# To be used within a Dockerfile, latest Ubuntu 20.04 LTS
# Installs:
#   - NodeJS (v14 LTS)
#   - Ghost CMS through Ghost-CLI
#   - Run as non-root $USER (see $MYUSER)
#   - Entrypoint set to ghost cli
# 
# Script written on 2021-06-25
# Dockerfile not quite working the way I wanted, reworking this for LXD deployment
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
set -u # Error on unset variable
set -e # Error on non-zero exit code
set -o pipefail # Error when pipe failed


# Variables --------------------------------------------------------------------
MYUSER="node"
MYPASSWD="node_123"
GOSU_VER="1.13"


# Create user $MYUSER ----------------------------------------------------------
initialization() {
  printf "  [INFO] Creating user ${MYUSER}\n"
  useradd \
    -d /home/"$MYUSER" $MYUSER
  echo "$MYUSER:$MYPASSWD" | chpasswd
  mkdir -p /home/"$MYUSER"
  chown -R "$MYUSER":"$MYUSER" /home/"$MYUSER"
  printf "  [INFO] User $MYUSER successfully configured\n"
}


# Upgrade and install node -----------------------------------------------------
install_node() {
  printf "  [INFO] Upgrading packages\n"
  apt --yes update > /dev/null 2>&1
  apt --yes upgrade > /dev/null 2>&1
  printf "  [INFO] Installing packages\n"
  apt --yes install sudo curl nano wget zsh net-tools nginx neovim htop > /dev/null 2>&1
  
  printf "  [INFO] Installing node v14 LTS from NodeSource\n"
  curl -fsSL https://deb.nodesource.com/setup_14.x | bash - > /dev/null 2>&1
  apt --yes install nodejs > /dev/null 2>&1

  printf "  [INFO] Installing Ghost CLI\n"
  npm install ghost-cli@latest -g > /dev/null 2>&1
}


# Install mysql ----------------------------------------------------------------
install_mysql() {
  printf "  [INFO] Installing MySQL\n"
  apt install --yes mysql-server > /dev/null 2>&1
}


# Update sudoers file ----------------------------------------------------------
update_sudoer() {
  printf "  [INFO] Updating sudoers file\n"
  echo "${MYUSER} ALL=(ALL:ALL) ALL" | EDITOR="tee --append" visudo > /dev/null 2>&1
  printf "  [INFO] Added ${MYUSER} to visudo\n"
}


# Cleanup step -----------------------------------------------------------------
cleanup() {
  printf "  [INFO] Running cleanup\n"
  rm -rf /var/lib/apt/lists/*
  npm cache clean --force > /dev/null 2>&1
  printf "  [INFO] Cleanup complete\n"
}


# Install gosu for user privilege de-escalation --------------------------------
install_gosu() {
  printf "  [INFO] Installing gosu\n"
  wget -O /usr/local/bin/gosu \
    "https://github.com/tianon/gosu/releases/download/$GOSU_VER/gosu-amd64" > /dev/null 2>&1
  chmod +x /usr/local/bin/gosu
  printf "  [INFO] gosu successfully installed\n"
}


# Configure zsh ----------------------------------------------------------------
configure_zsh() {
  printf "  [INFO] Configuring zsh\n"
  chsh -s $(which zsh)
  sudo -u $MYUSER chsh -s $(which zsh) 
}


# Main program -----------------------------------------------------------------
initialization
install_node
install_mysql
update_sudoer
#install_gosu
configure_zsh
cleanup
