#!/usr/bin/env bash
# ps -o args= -p "$$"

# set -e
SCRIPTPATH="$(cd "$(dirname "$0")";pwd -P)"

for include in .logging.include .config.include .mail.include
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

MAIL_TO="$(get_config .secret/.config.ini mail.TO)"
# sendmail "${MAIL_TO}" "ROUTER DOWN" "router is down"

MAIN_IP="$(get_config .secret/.config.ini ip-addresses.MAIN)"
SUB_IP="$(get_config .secret/.config.ini ip-addresses.SUB)"

info "main ip: ${MAIN_IP}"
info "sub ip: ${SUB_IP}"


DEBUG=false
if $DEBUG
then
	TIME_UNIT=1
else
	TIME_UNIT=$(get_config .secret/.config.ini timers.time-unit)
fi
info "time unit: ${TIME_UNIT}"


LOOP_SLEEP_VALUE=$(get_config .secret/.config.ini timers.LOOP-SLEEP-VALUE)
LOOP_SLEEP=$((TIME_UNIT*LOOP_SLEEP_VALUE))

MAIN_ERROR_SLEEP_VALUE=$(get_config .secret/.config.ini timers.MAIN-ERROR-SLEEP-VALUE)
MAIN_ERROR_SLEEP=$((TIME_UNIT*MAIN_ERROR_SLEEP_VALUE))
MAIN_ERROR_COUNTER=0
MAIN_MAIL_RETRIES=$(get_config .secret/.config.ini timers.MAIN-MAIL-RETRIES)


SUB_ERROR_SLEEP_VALUE=$(get_config .secret/.config.ini timers.SUB-ERROR-SLEEP-VALUE)
SUB_ERROR_SLEEP=$((TIME_UNIT*SUB_ERROR_SLEEP_VALUE))
SUB_ERROR_COUNTER=0
SUB_MAIL_RETRIES=$(get_config .secret/.config.ini timers.SUB-MAIL-RETRIES)

info "LOOP_SLEEP: ${LOOP_SLEEP}"
info "MAIN_ERROR_SLEEP: ${MAIN_ERROR_SLEEP}"
info "MAIN_ERROR_COUNTER: ${MAIN_ERROR_COUNTER}"
info "MAIN_MAIL_RETRIES: ${MAIN_MAIL_RETRIES}"
info "SUB_ERROR_SLEEP: ${SUB_ERROR_SLEEP}"
info "SUB_ERROR_COUNTER: ${SUB_ERROR_COUNTER}"
info "SUB_MAIL_RETRIES: ${SUB_MAIL_RETRIES}"

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
