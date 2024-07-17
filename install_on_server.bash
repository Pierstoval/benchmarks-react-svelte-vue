#!/bin/bash

set -e

CWD=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

cd "$CWD"

NVM_VERSION="v0.39.7"
if [[ -z "${NODE_VERSION}" ]]; then
  NODE_VERSION=20
fi

set -u

##
## Base dependencies
##
sudo apt-get update
sudo apt-get install -y \
  git \
  gcc \
  pkg-config \
  jq `# Used for graph generation` \
  libfreetype6-dev libfontconfig1-dev `# Used by Rust Plotters crate` \

##
## Rust
##
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

##
## Processtime is used to calculate build duration
##
cargo install processtime

##
## NVM & Node
##
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[[ -f "${HOME}/.bashrc" ]] && source "${HOME}/.bashrc" && echo "Sourced .bashrc"
nvm install 20
node -v

# Yarn package manager
npm i -g npm yarn

# pnpm package manager
wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
pnpm add -g pnpm

# Install http server for runtime tests
npx http-server --help

##
## Systemd service installation
##
CONTENT=$(cat <<EOF
[Unit]
Description=Benchmark frontend frameworks

[Service]
Type=simple
User=${USER}
Restart=always
RestartSec=3
WorkingDirectory=${CWD}
ExecStart=/bin/bash --login ${CWD}/bench_it_all.bash server

[Install]
WantedBy=multi-user.target
EOF
)

echo "${CONTENT}" | sudo tee /etc/systemd/system/benchmark-frontend-frameworks.service
sudo systemctl daemon-reload
sudo systemctl start benchmark-frontend-frameworks.service

##
## Playwright and browsers
##
yarn install
yarn playwright install-deps  # Install browser dependencies, might use sudo
yarn playwright install       # Install browsers themselves

##

echo "Done!"
