#!/bin/bash

CWD=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

set -e

cd "$CWD"

##
## Display functions
##

info_ln() {
    printf "\033[32m%s\033[0m ${1}\n" "[INFO]"
}
err() {
    printf " \033[31m%s\033[0m ${1}\n" "[ERROR]"
}

if [[ -z "${OUTPUT_DIR}" ]]; then
    OUTPUT_DIR=$1
fi

set -u

if [[ -z "$OUTPUT_DIR" ]]; then
    err "Please specify the output directory name either as an argument to this script, or with the OUTPUT_DIR environment variable"
    err "Available values:"
    output_directories=$(cd "${CWD}/output" && for f in *; do if [ -d "$f" ]; then echo -n "$f " ; fi ; done)
    err "  $output_directories"
    exit 1
fi

info_ln "Building the \"graphs\" binary so we can generate graphs:"
cargo build --release --manifest-path="$PWD/graphs/Cargo.toml"
info_ln "Done!"

TEST_OUT_DIR="${CWD}/output/${OUTPUT_DIR}"

if [[ ! -d "${TEST_OUT_DIR}" ]]; then
    err "Tests output directory \"${TEST_OUT_DIR}\" does not exist."
    err "Did you forget to execute the benchmarks with the \"\033[32m%s${CWD}/bench_it_all.bash ${OUTPUT_DIR}\033[0m\" command?"
    exit 1
fi

info_ln "Now Generating graphs from CSV data in \"${TEST_OUT_DIR}\""
"${CWD}/graphs/target/release/graphs" "${OUTPUT_DIR}"
info_ln "Done!"
