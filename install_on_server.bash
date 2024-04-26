#!/bin/bash

set -e

NVM_VERSION="v0.39.7"
if [[ -z "${NODE_VERSION}" ]]; then
  NODE_VERSION=20
fi

set -u

# Base dependencies
sudo apt-get update
sudo apt-get install \
  git \
  jq \


## NVM
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
[[ -f "${HOME}/.bashrc" ]] && . "${HOME}/.bashrc"
nvm install 20
node -v

##
echo "Done!"
