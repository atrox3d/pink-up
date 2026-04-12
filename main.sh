#!/usr/bin/env zsh

##############################################################################
# TODO: check pc connection before checking remote router
# TODO: add logfiles checklist
##############################################################################



##############################################################################
# MAIN SCRIPT VARS
##############################################################################
setopt PIPE_FAIL
set -e
SCRIPTPATH="$(cd "$(dirname "$0")";pwd -P)"
LOGFILE="${SCRIPTPATH}/pinkup.log"
SUMMARY_LOGFILE="${SCRIPTPATH}/summary.log"
CRONWRAPPER_LOGFILE="${SCRIPTPATH}/cron-wrapper.log"
ERRORFILE="${SCRIPTPATH}/ping-errors.txt"


function mail_ok() {
	sendmail "${MAIL_TO}" "${MAIL_CC}" "ROUTER UP" "router at ${MAIN_IP} is UP again"
	# update main and summary log
	[ $? -eq 0 ] && {
		info "mail sent correctly"             | tee -a "${SUMMARY_LOGFILE}"
	} || {
		error "mail not sent"                  | tee -a "${SUMMARY_LOGFILE}"
	}
}

function mail_ko() {
	sendmail "${MAIL_TO}" "${MAIL_CC}" "ROUTER DOWN" "router at ${MAIN_IP} is DOWN"
	# update main and summary log
	[ $? -eq 0 ] && {
		info "mail sent correctly"             | tee -a "${SUMMARY_LOGFILE}"
	} || {
		error "mail not sent"                  | tee -a "${SUMMARY_LOGFILE}"
	}
}


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
	# info "CONFIG_PATH=${CONFIG_PATH}"
	log_var "CONFIG_PATH"

	MAIL_TO="$(get_config "${CONFIG_PATH}" mail.TO)"
	MAIL_CC="$(get_config "${CONFIG_PATH}" mail.CC)"
	
	SMTP_SERVER="$(get_config "${CONFIG_PATH}" mail.SMTP-SERVER)"
	
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
	# print config and vars values
	##############################################################################
	log_var "SMTP_SERVER"
	log_var "MAIN_IP"
	log_var "MAIL_TO"
	log_var "MAIL_CC"
	log_var "MAIN_ERROR_COUNTER"
	log_var "LOGFILE"
	log_var "SUMMARY_LOGFILE"
	log_var "CRONWRAPPER_LOGFILE"
	log_var "ERRORFILE"

	##############################################################################
	#
	# PRE-FLIGHT CONNECTIVITY CHECK
	#
	##############################################################################	
	for host_to_check in "google.com" "${SMTP_SERVER}"
	do
		info "PRE-CHECK: pinging main ip ${host_to_check}"
		if ! ping -c5 "${host_to_check}" >/dev/null 2>&1
		then
			error "cannot ping ${host_to_check}"  | tee -a "${SUMMARY_LOGFILE}"
			die 1 "exiting, cannot check pre-flight connectivity"
		else
			info "PRE-CHECK OK: ${host_to_check}" | tee -a "${SUMMARY_LOGFILE}"
		fi
	done
	
	##############################################################################
	#
	#
	# main ip check
	#
	#
	##############################################################################
	info pinging main ip "${MAIN_IP}"
	if ! ping -c5 "${MAIN_IP}" >/dev/null 2>&1
	then
		##############################################################################
		#
		# ping fail
		#
		##############################################################################
		MAIN_ERROR_COUNTER=$((MAIN_ERROR_COUNTER+1))

		# update main and summary log
		error "ping ${MAIN_IP} failed"             | tee -a "${SUMMARY_LOGFILE}"
		error "error count: ${MAIN_ERROR_COUNTER}" | tee -a "${SUMMARY_LOGFILE}"

		##############################################################################
		# send mail
		##############################################################################
		info "sending mail for main ip"
		mail_ko

		##############################################################################
		# update error counter file
		##############################################################################
		info "updating ${ERRORFILE}"
		echo ${MAIN_ERROR_COUNTER} > "${ERRORFILE}"

		die 1 "error pinging main ip"
	else
		##############################################################################
		#
		# ping success
		#
		##############################################################################
		# update main and summary log
		info "main ip ${MAIN_IP} ok"                   | tee -a "${SUMMARY_LOGFILE}"

		##############################################################################
		# if this run is ok and error count > 0 last run terminated in error
		# - remove error counter file
		# - send mail router up again (just once)
		##############################################################################
		if [ $MAIN_ERROR_COUNTER -gt 0 ]
		then
			##############################################################################
			# remove error counter file when solved
			##############################################################################
			info "removing ${ERRORFILE}"
			rm ${ERRORFILE}

			mail_ok
		fi
	fi

} 2>&1 | tee -a "${LOGFILE}"
