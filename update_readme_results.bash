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

if [ "${DEBUG}" ]; then
    set -x
fi

#set -eu

custom_cat() {
    file=${CWD}/output/$1/angular.csv
    sed '1d' < "$file"
}

get_amount() {
    sed '1d' < "${CWD}/output/$1/angular.csv" | awk -F ';' '{print $1,$2,$3,$4,$5}' | wc -l
}

get_runtime_amount() {
    sed '1d' < "${CWD}/output/$1/angular.csv" | awk -F ';' '{print $6,$7,$8}' | grep -v "0 0 0" -c
}

numberVps=$(get_amount 'vps')
numberVpsRuntime=$(get_runtime_amount 'vps')

numberLocal=$(get_amount 'local')
numberLocalRuntime=$(get_runtime_amount 'local')

sed -i README.md -e "s~\(Number of build benchmarks\).*~\1   | $numberVps | $numberLocal |~gi"
sed -i README.md -e "s~\(Number of runtime benchmarks\).*~\1 | $numberVpsRuntime | $numberLocalRuntime |~gi"
