#!/bin/bash

set -eu



CWD=$(realpath $(dirname ${BASH_SOURCE[0]}))

cd "$CWD"

"${CWD}/test.bash"
"${CWD}/runtime_test.bash"

