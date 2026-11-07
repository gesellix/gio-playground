#!/usr/bin/env bash
# Checks the event log of a test run without a person at the screen (the CI
# workflow; PLAYGROUND_LOG in run.go):
#
#   scripts/check-log.sh LOG GIO [TEXT...]
#
# Waits up to CHECK_TIMEOUT seconds (default 60) until LOG has the start of
# the build GIO ("process started (Gio: GIO"), a FrameEvent and every TEXT,
# each a fixed string. Fails at once on a Go panic. LOG may also be a
# command that prints the log, given as "cmd:<command>" (adb logcat, a copy
# from the simulator), which runs again on each try. Prints the log at the
# end in any case.
set -euo pipefail

log=${1:?usage: $0 LOG GIO [TEXT...]}
gio=${2:?usage: $0 LOG GIO [TEXT...]}
shift 2
want=("process started (Gio: $gio," "FrameEvent size=" "$@")
timeout=${CHECK_TIMEOUT:-60}

read_log() {
	case $log in
	cmd:*) bash -c "${log#cmd:}" 2>/dev/null || true ;;
	*) cat "$log" 2>/dev/null || true ;;
	esac
}

missing=()
for ((i = 0; i <= timeout; i++)); do
	text=$(read_log)
	if grep -q -E 'panic: |fatal error: ' <<<"$text"; then
		echo "$text"
		echo "FAIL: the program panicked" >&2
		exit 1
	fi
	missing=()
	for w in "${want[@]}"; do
		grep -q -F -- "$w" <<<"$text" || missing+=("$w")
	done
	[ ${#missing[@]} -eq 0 ] && break
	sleep 1
done

echo "--- log ($log)"
read_log | grep -v -F 'FrameEvent size=' | head -n 200 || true
echo "--- $(read_log | grep -c -F 'FrameEvent size=' || true) FrameEvent lines (not shown)"
if [ ${#missing[@]} -gt 0 ]; then
	for w in "${missing[@]}"; do
		echo "FAIL: not in the log after ${timeout}s: $w" >&2
	done
	exit 1
fi
echo "PASS: $gio started, drew a frame and logged ${#want[@]} expected lines"
