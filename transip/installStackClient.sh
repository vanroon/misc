#!/bin/bash

#-- Install for Ubuntu 16.04 --#

# Add repository to sources
echo 'deb http://mirror.transip.net/stack/software/deb/Ubuntu_16.04/ ./' | sudo tee /etc/apt/sources.list.d/stack-client.list

# Add key to apt
wget -O - https://mirror.transip.net/stack/release.key | sudo apt-key add - 
sudo apt-get udpate

# Install client
sudo apt-get install stack-client

