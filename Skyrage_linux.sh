#!/bin/sh
printf '\033c\033]0;%s\a' SAE-jeu-video
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Skyrage_linux.x86_64" "$@"
