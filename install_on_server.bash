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

## Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

## NVM
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[[ -f "${HOME}/.bashrc" ]] && source "${HOME}/.bashrc" && echo "Sourced .bashrc"

nvm install 20
node -v

##
echo "Done!"
