#!/bin/bash

CWD=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

#
# Display functions
#

info_ln() {
    printf "\033[32m%s\033[0m %s\n" "[INFO]" "$1"
}
err() {
    printf " \033[31m[ERROR]\033[0m %s\n" "$1"
}

if [[ -z "${OUTPUT_DIR}" ]]; then
    OUTPUT_DIR=$1
fi

if [[ -z "$OUTPUT_DIR" ]]; then
    err "Please specify the output directory name either as an argument to this script, or with the OUTPUT_DIR environment variable"
    exit 1
fi

gnuplot -e "output_dir=\"${OUTPUT_DIR}\"" "${CWD}/graph.gnuplot"

info_ln "Done!"
