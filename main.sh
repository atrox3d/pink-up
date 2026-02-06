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
MAIN_SLEEP=5
SUB_SLEEP=5

# main loop
while true
do
	# main ip loop
	info pinging main ip "${MAIN_IP}"
	if ! ping -c5 "${MAIN_IP}" 2>&1 >/dev/null
	then
		error main ip error
		#send mail
		sleep ${MAIN_SLEEP}
		continue
	fi
	info main ip ok

	# sub ip check
	info pinging sub ip "${SUB_IP}"
	if ! ping -c5 "${SUB_IP}" 2>&1 >/dev/null
	then
		error sub iperror
		# send mail
		sleep ${SUB_SLEEP}
		continue
	else
		info sub ip ok
		info all ok
	fi
	sleep ${LOOP_SLEEP}
done

