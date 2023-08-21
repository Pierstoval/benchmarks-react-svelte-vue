#!/bin/bash

CWD=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

cd "$CWD"

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
    err "Available values:"
    output_directories=$(cd "${CWD}/output" && for f in *; do if [ -d "$f" ]; then echo -n "$f " ; fi ; done)
    err "  $output_directories"
    exit 1
fi

if [[ ! -f "${CWD}/graphs/target/release/graphs" ]]; then
    info_ln "First, building the \"graphs\" binary so we can generate graphs:"
    cargo build --release --manifest-path=graphs/Cargo.toml
    info_ln "Done!"
fi

info_ln "Generating graphs from CSV data in \"${CWD}/${OUTPUT_DIR}\""

cargo run --manifest-path=graphs/Cargo.toml -- "$OUTPUT_DIR"

info_ln "Done!"
