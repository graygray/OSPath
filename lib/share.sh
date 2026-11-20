log_step() {
	printf '>>>> %s\n' "$*"
}

log_separator() {
	if [ "$#" -eq 0 ]; then
		printf '%s\n' '=============================='
	else
		printf '========== %s ==========\n' "$1"
	fi
}

format_cmd() {
	local arg separator=""
	for arg in "$@"; do
		printf '%s' "$separator"
		if [[ "$arg" =~ ^[[:alnum:]_./:=,+@%-]+$ ]]; then
			printf '%s' "$arg"
		else
			arg=${arg//\\/\\\\}
			arg=${arg//\"/\\\"}
			arg=${arg//\$/\\\$}
			arg=${arg//\`/\\\`}
			printf '"%s"' "$arg"
		fi
		separator=" "
	done
}

run_cmd() {
	if [ "${1-}" = "--pipe" ]; then
		shift
		local -a producer=()
		while [[ $# -gt 0 && "$1" != "--" ]]; do
			producer+=("$1")
			shift
		done
		if [[ -z "${producer[0]+x}" || $# -lt 2 ]]; then
			printf 'Usage: run_cmd --pipe command [args] -- command [args]\n' >&2
			return 2
		fi
		shift
		log_step "$(format_cmd "${producer[@]}") | $(format_cmd "$@")" >&2
		"${producer[@]}" | "$@"
	else
		log_step "$@"
		"$@"
	fi
}
