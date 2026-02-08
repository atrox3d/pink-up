# !/usr/bin/env bash
# ps -o args= -p "$$"

# set -e
SCRIPTPATH="$(cd "$(dirname "$0")";pwd -P)"

for include in .logging .mail
do
	includepath="${SCRIPTPATH}/${include}"
	echo "INFO | checking ${includepath}"
	[ -f "${includepath}" ] || {
		echo "CRITICAL | cannot load ${includepath}"
		exit 1
	}
	echo "INFO | loading ${includepath}"
	source "${includepath}"
done


exit

MAIN_IP="$(cat "${SCRIPTPATH}/.secret/mainip.txt")"
SUB_IP="$(cat "${SCRIPTPATH}/.secret/subip.txt")"

DEBUG=false
if $DEBUG
then
	TIME_UNIT=1
else
	TIME_UNIT=60
fi

LOOP_SLEEP=$((TIME_UNIT*30))

MAIN_ERROR_SLEEP=$((TIME_UNIT*5))
MAIN_ERROR_COUNTER=0
MAIN_MAIL_RETRIES=3

SUB_ERROR_SLEEP=$((TIME_UNIT*5))
SUB_ERROR_COUNTER=0
SUB_MAIL_RETRIES=3

echo ${LOOP_SLEEP}
echo ${MAIN_ERROR_SLEEP}
echo ${SUB_ERROR_SLEEP}
exit

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
		if [ ${MAIN_ERROR_COUNTER} -ge ${MAIN_MAIL_RETRIES} ]
		then
			info sending mail for main ip
			MAIN_ERROR_COUNTER=0
		fi
		info sleeping ${MAIN_ERROR_SLEEP}
		sleep ${MAIN_ERROR_SLEEP}
		continue
	fi
	info main ip ok

	# sub ip check
	# info pinging sub ip "${SUB_IP}"
	# if ! ping -c5 "${SUB_IP}" >/dev/null 2>&1
	# then
	# 	error sub iperror
	# 	SUB_ERROR_COUNTER=$((SUB_ERROR_COUNTER+1))
	# 	error sub ip error count: ${SUB_ERROR_COUNTER}
	# 	# send mail
	# 	if [ ${SUB_ERROR_COUNTER} -ge ${SUB_MAIL_RETRIES} ]
	# 	then
	# 		info sending mail for main ip
	# 		SUB_ERROR_COUNTER=0
	# 	fi
	# 	sleep ${SUB_ERROR_SLEEP}
	# 	continue
	# else
	# 	info sub ip ok
	# 	info all ok
	# fi
	info sleeping ${LOOP_SLEEP}
	sleep ${LOOP_SLEEP}
done

