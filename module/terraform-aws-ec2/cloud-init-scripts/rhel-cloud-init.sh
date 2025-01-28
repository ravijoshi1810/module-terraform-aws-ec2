#!/bin/bash

# Add Local IAC User
sudo useradd -m -p $(openssl passwd -1 ${user_data_runtime_creds}) linuxadmin
#Enable Password Authentication
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/AllowGroups/#AllowGroups/g' /etc/ssh/sshd_config

#Restart ssh services
sudo service sshd restart

#Add Group to visudoers
echo "linuxadmin ALL=(ALL)       NOPASSWD: ALL" | sudo EDITOR="tee -a" visudo

