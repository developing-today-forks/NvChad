#!/usr/bin/env bash

printf "%s\n" "start: setup-nvim-for-user script"

SAVED_SHELL_OPTIONS=$(set +o)

# shellcheck disable=SC2317
restore_shell_options() {
  printf "%s\n" "trap start: restoring shell options"
  # printf "%s\n" "SAVED_SHELL_OPTIONS: ${SAVED_SHELL_OPTIONS}"
  # printf "%s\n" "CURRENT_SHELL_OPTIONS: $(set +o)"

  eval "${SAVED_SHELL_OPTIONS}"

  printf "%s\n" "trap done: restoring shell options"
}
trap restore_shell_options EXIT

set -euo pipefail

create_symlink() {
    local user home_dir target_dir source_dir

    user="$1"

    # Get home directory for the given user
    if ! home_dir=$(eval echo ~"$user"); then
        echo "Error: Failed to retrieve home directory for user $user." >&2
        exit 1
    fi

    target_dir="$home_dir/.config/nvim"
    source_dir="$(realpath "$(dirname "$(realpath "$0")")")"

    mkdir -p "$home_dir/.config"

    # Check if the target directory exists
    if [[ -e "$target_dir" ]]; then
        # If the target is a symlink
        if [[ -L "$target_dir" ]]; then
            # If it doesn't point to the source directory, panic!
            if [[ "$(readlink "$target_dir")" != "$source_dir" ]]; then
                echo "Error: $target_dir is a symlink, but not to $source_dir!" >&2
                exit 1
            fi
        else
            echo "Error: $target_dir exists and is not a symlink!" >&2
            exit 1
        fi
    else
        # Create a relative symlink
	printf "symlink: %s %s" "$source_dir" "$target_dir"
        ln -s "$source_dir" "$target_dir"
    fi
}

if [[ "$#" -eq 0 ]]; then
    # No arguments, just run for the current user
    create_symlink "$USER"
else
    for user in "$@"; do
        if [[ "$user" != "$USER" && "$EUID" -ne 0 ]]; then
            # If the user is not the current user and the script is not running as root, rerun with sudo
            sudo "$0" "$user"
        else
            create_symlink "$user"
        fi
    done
fi

printf "%s\n" "done: setup-nvim-for-user script"
