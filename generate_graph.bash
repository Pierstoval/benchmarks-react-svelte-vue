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

info_ln "Building the \"graphs\" binary so we can generate graphs:"
cargo build --release --manifest-path=graphs/Cargo.toml
info_ln "Done!"

info_ln "Now Generating graphs from CSV data in \"${CWD}/${OUTPUT_DIR}\""
"${CWD}/graphs/target/release/graphs" "$OUTPUT_DIR"
info_ln "Done!"
