#!/bin/bash

CWD=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

cd "$CWD"

info() {
    printf " %s" "$1"
}
err() {
    printf " \033[31m[ERROR]\033[0m %s\n" "$1"
}
ok() {
    printf " \033[32m%s\033[0m\n" "Done!"
}

if [[ -z "${OUTPUT_FILE}" ]]; then
    err "Please specify the OUTPUT_FILE env var before running the test suite."
    exit 1
fi

set -eu

OUTPUT_FILE=${OUTPUT_FILE} "${CWD}/test.bash"
OUTPUT_FILE=${OUTPUT_FILE} "${CWD}/runtime_test.bash"

info "Processing results into a graph..."

gnuplot -e "output_file=output/${OUTPUT_FILE}.png" "${CWD}/graph.gnuplot"

ok
