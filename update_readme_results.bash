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

numberDedi=$(getNumber 'dedi-2023-07')
numberDediRuntime=$(getNumber 'dedi-2023-07_runtime')

numberVps=$(getNumber 'vps')
numberVpsRuntime=$(getNumber 'vps_runtime')

numberLocal=$(getNumber 'local')
numberLocalRuntime=$(getNumber 'local_runtime')

sed -i README.md -e "s~\(Number of build benchmarks\).*~\1   | $numberDedi | $numberVps | $numberLocal |~gi"
sed -i README.md -e "s~\(Number of runtime benchmarks\).*~\1 | $numberDediRuntime | $numberVpsRuntime | $numberLocalRuntime |~gi"

# Number of dependencies
#
## Uses regex on yarn.lock to list all actual dependencies, regardless of multiple versions:
# find . -mindepth 2 -maxdepth 2 -name "yarn.lock" -exec bash -c "echo -n \"{} \" && rg -e '@[\^~<>=]*\d+' {} | sort -u | wc -l" \; | awk '{print $2,$1}' | sort -rn
#
## Uses "yarn list", which is supposed to be "the way™":
# find . -mindepth 2 -maxdepth 2 -name "yarn.lock" -exec bash -c "echo -n \"{} \" && yarn --cwd \$(dirname {}) list --silent | sed 's/^[^a-zA-Z0-9_@-]\+//g' | sed 's/@[0-9^~\.-]\+$//g' | sort -u | wc -l" \; | awk '{sub(/\/yarn.lock/, "") ; print $2,substr($1,3)}' | sort -rn
#
## Searches for node_modules dirs and counts them children:
# find . -mindepth 2 -maxdepth 2 -name "yarn.lock" | xargs dirname | xargs -I % bash -c "echo -n \"%  \" && find % -type d -name \"node_modules\" -exec bash -c 'echo -n \"{} \" && cd {} && ls -l | wc -l' \; | awk '{print \$2}' | awk '{s+=\$1} END {print s}' " | awk '{print $2,$1}' | sort -rn
#
## Uses "npm ls", which is *also* supposed to be "the way™", but gives different results than "yarn list", because nodejs:
# find . -mindepth 2 -maxdepth 2 -name "yarn.lock" | xargs dirname | xargs -I % bash -c "echo -n \"% \" && npm --prefix % ls -a -p | wc -l" | awk '{print $2,$1}' | sort -rn
