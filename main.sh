#!/usr/bin/env zsh

# set -e
SCRIPTPATH="$(cd "$(dirname "$0")";pwd -P)"
LOGFILE="${SCRIPTPATH}/pinkup.log"
ERRORFILE="${SCRIPTPATH}/ping-errors.txt"

{
	echo "SCRIPTPATH=${SCRIPTPATH}"
	echo "LOGFILE=${LOGFILE}"
	echo "PARAMS=${@}"
	echo "PARAM COUNT=${#@}"

	##############################################################################
	# 1) check shell: zsh or die
	##############################################################################
	RUNNING_SHELL=$(ps -o args= -p "$$"|cut -d' ' -f1)
	[ "${RUNNING_SHELL}" = zsh ] && {
		echo "running in shell: ${RUNNING_SHELL}"
	} || {
		echo "ERROR | this script is made to run in zsh"
		exit 1
	}

	##############################################################################
	# 2) load all modules or die
	##############################################################################

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

	##############################################################################
	# check params: debug
	##############################################################################
	[ "${1:l}" = debug ] && DEBUG=true || DEBUG=false
	log_var 'DEBUG'

	##############################################################################
	# when DEBUG is active set TIME_UNIT to 1 for testing
	##############################################################################
	CONFIG_PATH="${SCRIPTPATH}/.secret/.config.ini"
	if $DEBUG
	then
		debug "forcing TIME_UNIT to 1"
		TIME_UNIT=1
	else
		TIME_UNIT=$(get_config "${CONFIG_PATH}" timers.time-unit)
	fi
	log_var "TIME_UNIT"

	##############################################################################
	# load config from ini file
	##############################################################################
	info "CONFIG_PATH=${CONFIG_PATH}"

	MAIL_TO="$(get_config "${CONFIG_PATH}" mail.TO)"
	MAIL_CC="$(get_config "${CONFIG_PATH}" mail.CC)"

	# LOOP_SLEEP_VALUE=$(get_config "${CONFIG_PATH}" timers.LOOP-SLEEP-VALUE)
	# info "LOOP_SLEEP_VALUE=${LOOP_SLEEP_VALUE}"
	# LOOP_SLEEP=$((TIME_UNIT*LOOP_SLEEP_VALUE))

	MAIN_IP="$(get_config "${CONFIG_PATH}" ip-addresses.MAIN)"
	if $DEBUG && [ -n "${2}" ]; then
		debug "forcing main ip to ${2}"
		MAIN_IP="${2}"
	fi
	# MAIN_ERROR_SLEEP_VALUE=$(get_config "${CONFIG_PATH}" timers.MAIN-ERROR-SLEEP-VALUE)
	# MAIN_ERROR_SLEEP=$((TIME_UNIT*MAIN_ERROR_SLEEP_VALUE))
	if [ -f "${ERRORFILE}" ]
	then
		MAIN_ERROR_COUNTER=$(cat "${ERRORFILE}")
	else
		MAIN_ERROR_COUNTER=0
	fi
	# MAIN_MAIL_RETRIES=$(get_config "${CONFIG_PATH}" timers.MAIN-MAIL-RETRIES)

	# SUB_IP="$(get_config "${CONFIG_PATH}" ip-addresses.SUB)"
	# SUB_ERROR_SLEEP_VALUE=$(get_config "${CONFIG_PATH}" timers.SUB-ERROR-SLEEP-VALUE)
	# SUB_ERROR_SLEEP=$((TIME_UNIT*SUB_ERROR_SLEEP_VALUE))
	# SUB_ERROR_COUNTER=0
	# SUB_MAIL_RETRIES=$(get_config "${CONFIG_PATH}" timers.SUB-MAIL-RETRIES)

	##############################################################################
	# print config
	##############################################################################
	log_var "MAIN_IP"
	# log_var "SUB_IP"
	log_var "MAIL_TO"
	log_var "MAIL_CC"
	# log_var "LOOP_SLEEP"
	# log_var "MAIN_ERROR_SLEEP"
	log_var "MAIN_ERROR_COUNTER"
	# log_var "MAIN_MAIL_RETRIES"
	# log_var "SUB_ERROR_SLEEP"
	# log_var "SUB_ERROR_COUNTER"
	# log_var "SUB_MAIL_RETRIES"
	##############################################################################
	# main loop
	##############################################################################
	# while true
	# do


	##############################################################################
	# main ip check
	##############################################################################
	info pinging main ip "${MAIN_IP}"
	if ! ping -c5 "${MAIN_IP}" >/dev/null 2>&1
	then
		##############################################################################
		# ping fail
		##############################################################################
		MAIN_ERROR_COUNTER=$((MAIN_ERROR_COUNTER+1))
		error "ping ${MAIN_IP} failed"
		error "error count: ${MAIN_ERROR_COUNTER}"
		# if [ ${MAIN_ERROR_COUNTER} -ge ${MAIN_MAIL_RETRIES} ]
		# then
			##############################################################################
			# send mail
			##############################################################################
			info sending mail for main ip
			sendmail "${MAIL_TO}" "${MAIL_CC}" "ROUTER DOWN" "router at ${MAIN_IP} is down"
			# MAIN_ERROR_COUNTER=0
			info "updating ${ERRORFILE}"
			echo ${MAIN_ERROR_COUNTER} > "${ERRORFILE}"
			die 1 "error pinging main ip"
		# fi
		# info sleeping ${MAIN_ERROR_SLEEP}
		# sleep ${MAIN_ERROR_SLEEP}
		# continue
	fi
	info main ip ok
	# MAIN_ERROR_COUNTER=0
	if [ $MAIN_ERROR_COUNTER -gt 0 ]
	then
		info "removing ${ERRORFILE}"
		rm ${ERRORFILE}
	fi

	# ##############################################################################
	# # sub ip check
	# ##############################################################################
	# info "pinging sub ip ${SUB_IP}"
	# if ! ping -c5 "${SUB_IP}" >/dev/null 2>&1
	# then
	# 	##############################################################################
	# 	# ping fail
	# 	##############################################################################
	# 	SUB_ERROR_COUNTER=$((SUB_ERROR_COUNTER+1))
	# 	error "ping ${SUB_IP} failed"
	# 	error "error count: ${SUB_ERROR_COUNTER}"
	# 	if [ ${SUB_ERROR_COUNTER} -ge ${SUB_MAIL_RETRIES} ]
	# 	then
	# 		##############################################################################
	# 		# send mail
	# 		##############################################################################
	# 		info "sending mail for sub ip"
	# 		sendmail "${MAIL_TO}" "${MAIL_CC}" "SUB LINK DOWN" "link at ${SUB_IP} is down"
	# 		SUB_ERROR_COUNTER=0
	# 	fi
	# 	info "sleeping ${SUB_ERROR_SLEEP}"
	# 	sleep ${SUB_ERROR_SLEEP}
	# 	continue
	# fi
	# info "sub ip ok"
	# SUB_ERROR_COUNTER=0

	# info sleeping ${LOOP_SLEEP}
	# sleep ${LOOP_SLEEP}
	# done
} 2>&1 | tee -a "${LOGFILE}"
