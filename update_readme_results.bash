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

set -eu

getNumber() {
  echo $(node -e "process.stdout.write(String($(< "output/$1.csv" wc -l)-1))")
}

numberDedi=$(getNumber 'dedi')
numberDediRuntime=$(getNumber 'dedi_runtime')

numberVps=$(getNumber 'vps')
numberVpsRuntime=$(getNumber 'vps_runtime')

sed -i README.md -e "s~\(Number of build benchmarks\).*~\1   | $numberDedi | $numberVps |~gi"
sed -i README.md -e "s~\(Number of runtime benchmarks\).*~\1 | $numberDediRuntime | $numberVpsRuntime |~gi"
