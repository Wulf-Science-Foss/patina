#!/usr/bin/env bash

# Always die on error.
set -e

# Get the folder name of _this_ script.
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Get common stuff
source ${SRCDIR}/../modules/scripts/common/shell.sh

# Unset error handler!
trap - EXIT

printf "${magenta}"
message "Installing hooks!"
printf "${NC}"

git config core.hooksPath hooks
printf "${green}"
message "Hooks installed (core.hooksPath=hooks)"
printf "${NC}"
