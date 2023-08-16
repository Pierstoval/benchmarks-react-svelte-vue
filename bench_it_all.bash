#!/bin/bash

CWD=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

cd "$CWD"

#
# Display functions
#

info() {
    printf "    %s" "$1"
}
end_info_line_with_ok() {
    printf "\r \033[32m%s\033[0m\n" "✅"
}
info_ln() {
    printf " \033[32m%s\033[0m %s\n" "[INFO]" "$1"
}
note() {
    printf " \033[33m%s\033[0m\n" "$1"
}
text_note() {
    printf " %s \033[33m%s\033[0m\n" "$1" "$2"
}
err() {
    printf " \033[31m[ERROR]\033[0m %s\n" "$1"
}
end_info_line_with_error() {
    printf "\r \033[32m%s\033[0m\n" "❌"
}

#
# Input & dependencies checks
#

if [[ -z "${OUTPUT_DIR}" ]]; then
    OUTPUT_DIR=$1
fi

if [[ -z "${OUTPUT_DIR}" ]]; then
    err "Please specify the OUTPUT_DIR env var before running the test suite."
    exit 1
fi

info "Make sure processtime is installed..."
if ! command -v processtime &> /dev/null
then
    end_info_line_with_error
    err "processtime could not be found"
    err "Install it with \"cargo install processtime\"."
    exit 1
fi
end_info_line_with_ok

info "Make sure \"du\" command is available..."
if ! command -v du &> /dev/null
then
    end_info_line_with_error
    err "\"du\" command could not be found"
    err "Possible causes:"
    err " > You are not using a unix OS."
    err " > You did not install GNU core utils."
    exit 1
fi
end_info_line_with_ok

info "Make sure \"jq\" command is available..."
if ! command -v jq &> /dev/null
then
    end_info_line_with_error
    err "\"jq\" command could not be found"
    err "Please install it on your system using your preferred method (easier with your native package manager like apt, yum, apk, etc.)"
    exit 1
fi
end_info_line_with_ok

set -eu

#
# Helpers vars & functions
#

processtime=$(which processtime)
yarn=$(which yarn)
du=$(which du)

output_file_prefix() {
    app=$1
    extension=$2
    out_dir="${CWD}/output/${OUTPUT_DIR}/${app}"
    [[ -d "$out_dir" ]] || mkdir -p "$out_dir"
    echo "$out_dir.${extension}"
}

time_command() {
    # shellcheck disable=SC2086
    ${processtime} --format=ms -- $1 | tail -1
}

save_value_to_csv() {
  app=$1
  value=$2
  headers=$3
  filename=$(output_file_prefix "$app" "csv")

  if [[ ! -f "$filename" ]]; then
      if [[ -z "$headers" ]]; then
          touch "$filename"
      else
          echo "$headers" > "$filename"
      fi
  fi

  echo "$value" >> "$filename"
}

#
# Processing functions
#

process() {
    app=$1
    info "Cleanup..."
        git clean -fdx -- "apps/$app" >/dev/null 2>&1
    end_info_line_with_ok

    info "Install dependencies..."
        install_time=$(time_command "${yarn} --cwd=apps/$app --frozen-lockfile install" 2>/dev/null)
    end_info_line_with_ok

    info "Build static application..."
        build_time=$(time_command "${yarn} --cwd=apps/$app build" 2>/dev/null)
    end_info_line_with_ok

    info "Counting dependencies..."
        # Commands explanation:
        #    yarn --cwd apps/$app list --silent
        #    | sed 's/^[^a-zA-Z0-9_@-]\+//g'     # Remove the "└─" or "├─" tree-related characters
        #    | sed 's/@[0-9^~\.-]\+$//g'         # Remove the "@...` version tag
        #    | sort -u                           # Remove duplicate lines
        #    | wc -l                             # Counts number of elements
        deps_with_duplicates=$(yarn --cwd "apps/$app" list --silent | sed 's/^[^a-zA-Z0-9_@-]\+//g' | sort -u | wc -l)
        deps_without_duplicates=$(yarn --cwd "apps/$app" list --silent | sed 's/^[^a-zA-Z0-9_@-]\+//g' | sed 's/@[0-9^~\.-]\+$//g' | sort -u | wc -l)
    end_info_line_with_ok

    info "Determining build build_size..."
        dir="apps/$app/dist"
        if [[ ! -d "$dir" ]]; then
            end_info_line_with_error
            err "Could not determine build directory for \"$app\" application."
            err "Possible causes:"
            err "> No directory named \"dist\", \"build\" or \"out\"."
            err "> Build action was not run or returned an error."
            exit 1
        fi

        build_size=$(${du} -s "$dir" | awk '{print $1}')
    end_info_line_with_ok

    info "Running runtime benchmarks using Playwright..."
        # Using only one worker (with "-j 1") to make sure performance test are executed with only one app running.
        TEST_APP=$app ${yarn} playwright test -j 1

        report=$(< playwright-report/report.json jq -r '.suites[0].specs[] | .tests[0] | "\(.projectName) \(.results[0].duration)"' | sort)

        e2e_headers=$(echo "${report}" | awk '{print $1}' | tr '\n' ';' | sed '$ s/;$//')
        e2e_times=$(echo "${report}" | awk '{print $2}' | tr '\n' ';' | sed '$ s/;$//')
    end_info_line_with_ok

    save_value_to_csv \
        "$app" \
        "$install_time;$build_time;$deps_with_duplicates;$deps_without_duplicates;$build_size;$e2e_times" \
        "install_time;build_time;deps_with_duplicates;deps_without_duplicates;build_size;$e2e_headers"
}

#
# Processing
#

apps_directories=$(cd apps && for f in *; do if [ -d "$f" ]; then echo "$f" ; fi ; done)
# shellcheck disable=SC2206
apps_directories_array=($apps_directories)

shift # Drops first element of arguments
apps_to_process="$*" # Retrieves variadic elements after the first one (1st one excluded)

info_ln "apps_to_process: $apps_to_process"

if [[ -z $apps_to_process ]]
then
    note " Reminder: you can also add a second argument to this script if you want to run only one single test suite."
    note " Example:"
    curscript=$(basename "$0")
    randomapp=${apps_directories_array[ $RANDOM % ${#apps_directories_array[@]} ]}
    note "  $curscript ${OUTPUT_DIR} ${randomapp}"
fi

info_ln "Processing tests..."

echo "$apps_directories" | while IFS= read -r line ; do
    if [[ -z $apps_to_process || "$apps_to_process" == *"$line"* ]]; then
        note "Processing $line"
        process "$line"
    else
        note "Skipping $line..."
    fi
done

info_ln "Done!"
