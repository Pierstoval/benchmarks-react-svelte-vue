
##
## Display functions
##

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
    >&2 printf " \033[31m[ERROR]\033[0m %s\n" "$1"
}
end_info_line_with_error() {
    printf "\r \033[32m%s\033[0m\n" "❌"
}
