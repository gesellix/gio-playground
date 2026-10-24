#!/usr/bin/env bash
# Runs the playground on this computer: scripts/desktop.sh
. "$(dirname "$0")/lib.sh"

cd "$moddir" || exit
exec go run -ldflags "$(ldflags none)" .
