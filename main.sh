#!/usr/bin/env zsh

setopt PIPE_FAIL
# set -e
SCRIPTPATH="$(cd "$(dirname "$0")";pwd -P)"
LOGFILE="${SCRIPTPATH}/pinkup.log"
SUMMARY_LOGFILE="${SCRIPTPATH}/summary.log"
ERRORFILE="${SCRIPTPATH}/ping-errors.txt"

{
	##############################################################################
	# cannot use logger until imported
	# using echo
	##############################################################################
	echo "##############################################################################"
	echo "SCRIPTPATH=${SCRIPTPATH}"
	echo "LOGFILE=${LOGFILE}"
	echo "PARAMS=${@}"
	echo "PARAM COUNT=${#}"

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
		echo "INFO | checking: ${includepath}"
		[ -f "${includepath}" ] || {
			# update main and summary log
			echo "CRITICAL | cannot load ${includepath}" | tee -a "${SUMMARY_LOGFILE}"
			exit 1
		}
		echo "INFO | loading:  ${includepath}"
		source "${includepath}"
	done

	##############################################################################
	# check params: debug
	##############################################################################
	[ "${1:l}" = debug ] && DEBUG=true || DEBUG=false
	log_var 'DEBUG'

	##############################################################################
	#
	# *** SPAM WARNING ***
	#
	# when DEBUG is active set TIME_UNIT to 1 for testing
	#
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

	##############################################################################
	# print config values
	##############################################################################
	log_var "MAIN_IP"
	log_var "MAIL_TO"
	log_var "MAIL_CC"
	log_var "MAIN_ERROR_COUNTER"

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

		# update main and summary log
		error "ping ${MAIN_IP} failed"             | tee -a "${SUMMARY_LOGFILE}"
		error "error count: ${MAIN_ERROR_COUNTER}" | tee -a "${SUMMARY_LOGFILE}"

		##############################################################################
		# send mail
		##############################################################################
		info sending mail for main ip
		sendmail "${MAIL_TO}" "${MAIL_CC}" "ROUTER DOWN" "router at ${MAIN_IP} is DOWN"
		# update summary log
		[ $? -eq 0 ] && {
			info "mail sent correctly"             | tee -a "${SUMMARY_LOGFILE}"
		} || {
			error "mail not sent"                  | tee -a "${SUMMARY_LOGFILE}"
		}

		info "updating ${ERRORFILE}"
		echo ${MAIN_ERROR_COUNTER} > "${ERRORFILE}"
		die 1 "error pinging main ip"
	fi
	# update main and summary log
	info main ip ok                                | tee -a "${SUMMARY_LOGFILE}"

	##############################################################################
	# if error count > 0 last run terminated in error
	# - remove error counter file
	# - send mail router up again
	##############################################################################
	if [ $MAIN_ERROR_COUNTER -gt 0 ]
	then
		##############################################################################
		# remove error counter file when solved
		##############################################################################
		info "removing ${ERRORFILE}"
		rm ${ERRORFILE}

		sendmail "${MAIL_TO}" "${MAIL_CC}" "ROUTER UP" "router at ${MAIN_IP} is UP again"
		# update summary log
		[ $? -eq 0 ] && {
			info "mail sent correctly"             | tee -a "${SUMMARY_LOGFILE}"
		} || {
			error "mail not sent"                  | tee -a "${SUMMARY_LOGFILE}"
		}
	fi

} 2>&1 | tee -a "${LOGFILE}"
