#!/usr/bin/env bash

set -eu

CWD=$(realpath $(dirname ${BASH_SOURCE[0]}))

cd "$CWD"

info() {
    printf " %s" "$1"
}
ok() {
    printf " \033[32m%s\033[0m\n" "Done!"
}

yarn=$(which yarn)

if [ -f playwright-report/report.json ]; then
    info "Removing previous JSON report"
    rm playwright-report/report.json
    ok
fi

info "Checking if sites are built."

if [ ! -f ./react/build/index.html ]; then
    info "Rebuilding all projects as static sites"
    info " > Svelte Build"      && ${yarn} --cwd=svelte build && ok
    info " > Svelte Kit Build"  && ${yarn} --cwd=svelte-kit build && ok
    info " > React Build"       && ${yarn} --cwd=react build && ok
    info " > React Vite Build"  && ${yarn} --cwd=react-vite build && ok
    info " > React Next Build"  && ${yarn} --cwd=react-next build && ok
    info " > Vue Build"         && ${yarn} --cwd=vue build && ok
    info " > Vue Nuxt Build"    && ${yarn} --cwd=vue-nuxt generate && ok
else
    ok
fi

info "Executing all tests on all apps using Playwright"
# Using only one worker (with "-j 1") to make sure performance test are executed with only one app running.
${yarn} playwright test -j 1
ok

info "Fetching JSON report"

report=$(cat playwright-report/report.json | jq '.suites[0].specs[] | .tests[0] | "\(.projectName):\(.results[0].duration)"')

csvHeader=""
csvLine=""

while IFS= read -r line; do
    line=${line//\"}
    line=${line// /_}
    arr=(${line//:/ })
    if [[ -z "$csvHeader" ]]; then
        csvHeader="${arr[0]}"
    else
        csvHeader="${csvHeader};${arr[0]}"
    fi
    if [[ -z "$csvLine" ]]; then
        csvLine="${arr[1]}"
    else
        csvLine="${csvLine};${arr[1]}"
    fi
done <<< "$report"

ok

info "Adding execution times to $(realpath results_runtime.csv) file"

echo "$csvLine" >> results_runtime.csv

ok
