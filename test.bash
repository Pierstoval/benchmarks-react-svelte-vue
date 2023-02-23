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

info "Retrieving CSV headers..."
cat results.csv | head -1 > headers.csv
ok

info "Cleaning up..."
rm -rf \
    \
    react/node_modules \
    react/build \
    \
    react-vite/node_modules \
    react-vite/.next \
    react-vite/next-env.d.ts \
    react-vite/dist \
    \
    react-next/node_modules \
    react-next/.next \
    react-next/next-env.d.ts \
    react-next/out \
    \
    svelte/node_modules \
    svelte/dist \
    \
    svelte-kit/node_modules \
    svelte-kit/.svelte-kit \
    svelte-kit/build \
    \
    vue/node_modules \
    vue/dist \
    \
    vue-nuxt/node_modules \
    vue-nuxt/.nuxt \
    vue-nuxt/dist \

ok

info "Making sure processtime is installed..."
if ! command -v processtime &> /dev/null
then
    echo "processtime could not be found"
    echo "Install it with \"cargo install processtime\"."
    exit 1
fi
ok

processtime=$(which processtime)
yarn=$(which yarn)
du=$(which du)

info "Installing node dependencies..." && printf "\n"
info " > Svelte Yarn"      && svelte_yarn=$(${processtime} --format=ms -- ${yarn} --frozen-lockfile --cwd=svelte | tail -1) && ok
info " > Svelte Kit Yarn"  && svelte_kit_yarn=$(${processtime} --format=ms -- ${yarn} --frozen-lockfile --cwd=svelte-kit | tail -1) && ok
info " > React Yarn"       && react_yarn=$(${processtime} --format=ms -- ${yarn} --frozen-lockfile --cwd=react | tail -1) && ok
info " > React Vite Yarn"  && react_vite_yarn=$(${processtime} --format=ms -- ${yarn} --frozen-lockfile --cwd=react-vite | tail -1) && ok
info " > React Next Yarn"  && react_next_yarn=$(${processtime} --format=ms -- ${yarn} --frozen-lockfile --cwd=react-next | tail -1) && ok
info " > Vue Yarn"         && vue_yarn=$(${processtime} --format=ms -- ${yarn} --cwd=vue | tail -1) && ok
info " > Vue Nuxt Yarn"    && vue_nuxt_yarn=$(${processtime} --format=ms -- ${yarn} --cwd=vue-nuxt | tail -1) && ok

info "Building projects as static websites..." && printf "\n"
info " > Svelte Build"      && svelte_build=$(${processtime} --format=ms -- ${yarn} --cwd=svelte build | tail -1) && ok
info " > Svelte Kit Build"  && svelte_kit_build=$(${processtime} --format=ms -- ${yarn} --cwd=svelte-kit build | tail -1) && ok
info " > React Build"       && react_build=$(${processtime} --format=ms -- ${yarn} --cwd=react build | tail -1) && ok
info " > React Vite Build"  && react_vite_build=$(${processtime} --format=ms -- ${yarn} --cwd=react-vite build | tail -1) && ok
info " > React Next Build"  && react_next_build=$(${processtime} --format=ms -- ${yarn} --cwd=react-next build | tail -1) && ok
info " > Vue Build"         && vue_build=$(${processtime} --format=ms -- ${yarn} --cwd=vue build | tail -1) && ok
info " > Vue Nuxt Build"    && vue_nuxt_build=$(${processtime} --format=ms -- ${yarn} --cwd=vue-nuxt generate | tail -1) && ok

info "Gathering complete build size..." && printf "\n"
info " > Svelte Build Size"      && svelte_build_size=$(${du} -s svelte/dist/ | awk '{print $1}') && ok
info " > Svelte Kit Build Size"  && svelte_kit_build_size=$(${du} -s svelte-kit/build/ | awk '{print $1}') && ok
info " > React Build Size"       && react_build_size=$(${du} -s react/build/ | awk '{print $1}') && ok
info " > React Vite Build Size"  && react_vite_build_size=$(${du} -s react-vite/dist/ | awk '{print $1}') && ok
info " > React Next Build Size"  && react_next_build_size=$(${du} -s react-next/out/ | awk '{print $1}') && ok
info " > Vue Build Size"         && vue_build_size=$(${du} -s vue/dist/ | awk '{print $1}') && ok
info " > Vue Nuxt Build Size"    && vue_nuxt_build_size=$(${du} -s vue-nuxt/dist/ | awk '{print $1}') && ok

info "Results for node dependencies:" && printf "\n"
echo " ➡ svelte yarn install:       ${svelte_yarn} ms"
echo " ➡ svelte_kit yarn install:   ${svelte_kit_yarn} ms"
echo " ➡ react yarn install:        ${react_yarn} ms"
echo " ➡ react_vite yarn install:   ${react_vite_yarn} ms"
echo " ➡ react_next yarn install:   ${react_next_yarn} ms"
echo " ➡ vue yarn install:          ${vue_yarn} ms"
echo " ➡ vue nuxt yarn install:     ${vue_nuxt_yarn} ms"

info "Results for build time:" && printf "\n"
echo " ➡ svelte build time:       ${svelte_build} ms"
echo " ➡ svelte-kit build time:   ${svelte_kit_build} ms"
echo " ➡ react build time:        ${react_build} ms"
echo " ➡ react-vite build time:   ${react_vite_build} ms"
echo " ➡ react-next build time:   ${react_next_build} ms"
echo " ➡ vue build time:          ${vue_build} ms"
echo " ➡ vue nuxt build time:     ${vue_nuxt_build} ms"

info "Results for build size:" && printf "\n"
echo " ➡ svelte build size:       ${svelte_build_size} KB"
echo " ➡ svelte_kit build size:   ${svelte_kit_build_size} KB"
echo " ➡ react build size:        ${react_build_size} KB"
echo " ➡ react_vite build size:   ${react_vite_build_size} KB"
echo " ➡ react_next build size:   ${react_next_build_size} KB"
echo " ➡ vue build size:          ${vue_build_size} KB"
echo " ➡ vue nuxt build size:     ${vue_nuxt_build_size} KB"

CSVLINE=""
CSVLINE+="${svelte_yarn};"
CSVLINE+="${svelte_kit_yarn};"
CSVLINE+="${react_yarn};"
CSVLINE+="${react_vite_yarn};"
CSVLINE+="${react_next_yarn};"
CSVLINE+="${vue_yarn};"
CSVLINE+="${vue_nuxt_yarn};"

CSVLINE+="${svelte_build};"
CSVLINE+="${svelte_kit_build};"
CSVLINE+="${react_build};"
CSVLINE+="${react_vite_build};"
CSVLINE+="${react_next_build};"
CSVLINE+="${vue_build};"
CSVLINE+="${vue_nuxt_build};"

CSVLINE+="${svelte_build_size};"
CSVLINE+="${svelte_kit_build_size};"
CSVLINE+="${react_build_size};"
CSVLINE+="${react_vite_build_size};"
CSVLINE+="${react_next_build_size};"
CSVLINE+="${vue_build_size};"
CSVLINE+="${vue_nuxt_build_size};"

echo "${CSVLINE::-1}" >> results.csv

info "Processing results into a graph..."

gnuplot graph.gnuplot

ok
