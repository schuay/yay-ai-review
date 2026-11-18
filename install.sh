#!/usr/bin/env bash
# Usage: install.sh [-u]
#
# Enables the hook for the current user by loading hook.lua, from the directory
# this script is in, in yay's init.lua. -u disables it again.

set -euo pipefail

dir=$(dirname "$(realpath "$0")")
init=${XDG_CONFIG_HOME:-$HOME/.config}/yay/init.lua
marker='-- yay-ai-review'

[[ -f $init ]] && sed -i "/$marker\$/d" "$init"

if [[ ${1:-} == -u ]]; then
	echo "yay-ai-review disabled in $init"
	exit
fi

mkdir -p "$(dirname "$init")"
printf 'dofile([[%s/hook.lua]]) %s\n' "$dir" "$marker" >>"$init"
echo "yay-ai-review enabled in $init"

if backend=$("$dir/review" --backend); then
	echo "backend: $backend"
fi
