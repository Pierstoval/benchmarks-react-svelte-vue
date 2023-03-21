#!/bin/bash

set -eu

info() {
    printf " %s" "$1"
}
ok() {
    printf " \033[32m%s\033[0m\n" "Done!"
}

CWD=$(realpath $(dirname ${BASH_SOURCE[0]}))

cd "$CWD"

"${CWD}/test.bash"
"${CWD}/runtime_test.bash"

info "Processing results into a graph..."

gnuplot "${CWD}/graph.gnuplot"

ok

