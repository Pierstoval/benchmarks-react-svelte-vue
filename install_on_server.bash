#!/usr/bin/env bash

set -e

CWD=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

cd "$CWD"

. "$CWD/_helpers.bash"

NVM_VERSION="v0.40.8"
if [[ -z "${NODE_VERSION}" ]]; then
  NODE_VERSION=24
fi

set -u

##
## Base dependencies
##
info_ln "Installing system dependencies"
sudo apt-get update
sudo apt-get install -y \
  git \
  gcc \
  pkg-config \
  jq `# Used for graph generation` \
  libfreetype6-dev libfontconfig1-dev `# Used by Rust Plotters crate` \
  xvfb `# Virtual display for Playwright`

##
## Rust
##
if ! command -v cargo &> /dev/null
then
  info_ln "Installing Rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

##
## Processtime is used to calculate build duration
##
if ! command -v cargo &> /dev/null
then
  info_ln "Installing Processtime"
  cargo install processtime
fi

##
## NVM & Node
##
if ! command -v nvm &> /dev/null
then
  info_ln "Installing NVM"
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [[ -f "${HOME}/.bashrc" ]] && source "${HOME}/.bashrc" && echo "Sourced .bashrc"
  nvm install "$NODE_VERSION"
fi
node -v

# Package managers
info_ln "Installing Node package managers and runtime dependencies"
npm i -g npm yarn pnpm

# Install http server for runtime tests
pnpx --yes http-server --version

##
## Systemd service installation
##

info_ln "Installing systemd service"

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
pnpm install
pnpm playwright install-deps  # Install browser dependencies, might use sudo
pnpm playwright install       # Install browsers themselves

##

info "Done!"
