# !/usr/bin/env bash
# ps -o args= -p "$$"

set -e
SCRIPTPATH="$(cd "$(dirname "$0")";pwd -P)"
source "${SCRIPTPATH}/.functions" || {
	echo "cannot load ${SCRIPTPATH}/.functions"
	exit 1
}

MAIN_IP="$(cat "${SCRIPTPATH}/.secret/mainip.txt")"
SUB_IP="$(cat "${SCRIPTPATH}/.secret/subip.txt")"
LOOP_SLEEP=1
MAIN_SLEEP=1
SUB_SLEEP=1

while true
do
	info pinging main ip "${MAIN_IP}"
	while ! ping -c5 "${MAIN_IP}" 2>&1 >/dev/null
	do
		error main ip error
		sleep ${MAIN_SLEEP}
	done
	info main ip ok
	info pinging sub ip "${SUB_IP}"
	if ! ping -c5 "${SUB_IP}" 2>&1 >/dev/null
	then
		error sub iperror
		sleep ${SUB_SLEEP}
	else
		info sub ip ok
		info all ok
	fi
	sleep ${LOOP_SLEEP}
done

