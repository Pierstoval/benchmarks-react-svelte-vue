#!/bin/bash

CWD=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

cd "$CWD"

#
# Display functions
#

info() {
    printf "    %s" "$1"
}
note() {
    printf " \033[33m%s\033[0m\n" "$1"
}
infoln() {
    printf " \033[32m%s\033[0m %s\n" "[INFO]" "$1"
}
textnote() {
    printf " %s \033[33m%s\033[0m\n" "$1" "$2"
}
infoln() {
    printf " \033[32m%s\033[0m %s\n" "[INFO]" "$1"
}
err() {
    printf " \033[31m[ERROR]\033[0m %s\n" "$1"
}
ok() {
    printf "\r \033[32m%s\033[0m\n" "✅"
}
errinfo() {
    printf "\r \033[32m%s\033[0m\n" "❌"
}

#
# Input & dependencies checks
#

if [[ -z "${OUTPUT_FILE}" ]]; then
    err "Please specify the OUTPUT_FILE env var before running the test suite."
    exit 1
fi

info "Make sure processtime is installed..."
if ! command -v processtime &> /dev/null
then
    errinfo
    err "processtime could not be found"
    err "Install it with \"cargo install processtime\"."
    exit 1
fi
ok

info "Make sure \"du\" command is available..."
if ! command -v du &> /dev/null
then
    errinfo
    err "\"du\" command could not be found"
    err "Possible causes:"
    err " > You are not using a unix OS."
    err " > You did not install GNU core utils."
    exit 1
fi
ok

set -eu

#
# Helpers vars & functions
#

processtime=$(which processtime)
yarn=$(which yarn)
du=$(which du)

output_file_prefix() {
    app=$1
    suffix=$2
    echo "${CWD}/out/${app}${suffix}"
}

time_command() {
    ${processtime} --format=ms -- $1 | tail -1
}

save_value_to_csv() {
  app=$1
  type=$2
  value=$3
  echo $value >> $(output_file_prefix "$type.csv")
}

#
# Processing functions
#

process() {
    app=$1
    note "$app:"
    cleanup $app
    yarn_install "$app"
    yarn_build "$app"
    dependencies "$app"
    build_size "$app"
    runtime_bench "$app"
}

cleanup() {
    app=$1
    info "Cleanup..."
        git clean -fdx -- "apps/$app"
    ok
}

yarn_install() {
    app=$1
    info "Install dependencies..."
        time=$(time_command "${yarn} --cwd=apps/$app --frozen-lockfile install")
    ok
    save_value_to_csv $app "install_time" $time
}

yarn_build() {
    app=$1
    info "Install dependencies..."
        time=$(time_command "${yarn} --cwd=apps/$app build")
    ok
    save_value_to_csv $app "build_time" $time
}

dependencies() {
    app=$1

    info "Counting dependencies..."
        # Commands explanation:
        #    yarn --cwd apps/$app list --silent
        #    | sed 's/^[^a-zA-Z0-9_@-]\+//g'     # Remove the "└─" or "├─" tree-related characters
        #    | sed 's/@[0-9^~\.-]\+$//g'         # Remove the "@...` version tag
        #    | sort -u                           # Remove duplicates (will effectively not count 2 versions as 2 dependencies)
        #    | wc -l                             # Counts number of elements

        amount_with_duplicates=$(yarn --cwd apps/$app list --silent \ | sed 's/^[^a-zA-Z0-9_@-]\+//g' \ | sed 's/@[0-9^~\.-]\+$//g' \ | wc -l)
        amount_without_duplicates=$(yarn --cwd apps/$app list --silent \ | sed 's/^[^a-zA-Z0-9_@-]\+//g' \ | sed 's/@[0-9^~\.-]\+$//g' \ | sort -u \ | wc -l)
    ok

    save_time $app "dependencies_amount_with_duplicates" $amount_with_duplicates
    save_time $app "dependencies_amount_without_duplicates" $amount_without_duplicates
}

build_size() {
    app=$1

    info "Determining build size..."
        if [[ -d "apps/$app/dist" ]]; then
            dir="apps/$app/dist"
        elif [[ -d "apps/$app/build" ]]; then
            dir="apps/$app/build"
        elif [[ -d "apps/$app/out" ]]; then
            dir="apps/$app/out"
        else
            errinfo
            err "Could not determine build directory for \"$app\" application."
            err "Possible causes:"
            err "> No directory named \"dist\", \"build\" or \"out\"."
            err "> Build action was not run or returned an error."
        fi

        size=$(${du} -s "$dir" | awk '{print $1}')
    ok

    save_value_to_csv $app "build_size" $time
}

runtime_bench() {
    infoln " TODO "
}

#
# Processing
#

apps_directories=$(cd apps && for f in *; do if [ -d "$f" ]; then echo "$f" ; fi ; done)

infoln "Processing all directories one by one..."

echo "$apps_directories" | while IFS= read -r line ; do
    process "$line"
done
