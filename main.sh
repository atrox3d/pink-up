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
LOOP_SLEEP=5
MAIN_ERROR_SLEEP=5
MAIN_ERROR_COUNTER=0
SUB_ERROR_SLEEP=5
SUB_ERROR_COUNTER=0

# main loop
while true
do
	# main ip loop
	info pinging main ip "${MAIN_IP}"
	if ! ping -c5 "${MAIN_IP}" >/dev/null 2>&1
	then
		MAIN_ERROR_COUNTER=$((MAIN_ERROR_COUNTER+1))
		error main ip error count: ${MAIN_ERROR_COUNTER}
		#send mail
		sleep ${MAIN_ERROR_SLEEP}
		continue
	fi
	info main ip ok

	# sub ip check
	info pinging sub ip "${SUB_IP}"
	if ! ping -c5 "${SUB_IP}" >/dev/null 2>&1
	then
		error sub iperror
		SUB_ERROR_COUNTER=$((SUB_ERROR_COUNTER+1))
		error sub ip error count: ${SUB_ERROR_COUNTER}
		# send mail
		sleep ${SUB_ERROR_SLEEP}
		continue
	else
		info sub ip ok
		info all ok
	fi
	sleep ${LOOP_SLEEP}
done

