#!/bin/bash
# Author: David Pflug (dpflug@circuit5.org)
# Intended to be used via cron at 12:30 AM and PM, but can be run any time
# Assumes 2 shifts per day

setmail() {
    # Called with username

    #sed "s/helpdesk-usa:.*/helpdesk-usa: $user/"
    #newaliases
    #/etc/init.d/postfix reload

    ( echo "To: Court Tech <court_technology_department@circuit5.org>"
      echo "Subject: Setting $1 onduty for RT"
      echo "From: Mail Update Script <dpflug@circuit5.org>"
      echo ""
      if [ "$NOOP" != 1 ] ; then
	  /adm/bin/rtonduty_change.sh "$1"
      else
	  echo "NOOP RUN - No change made"
      fi ) | sendmail -t
}

SHIFT_CHANGE=1230
SHIFTS_END=1730
DESK_JOCKEYS=(
    # First option is who to send to by default
    # We default to the entire Court Tech department
    "allcourttech"
    "reckelberry"
    "jkidd"
    "broberts"
    "sunderwood"
    "rellerbee"
    "dpflug"
    "kmorse"
    "jkidd"
    "reckelberry"
    "sunderwood"
    "broberts"
    "rellerbee"
    "kmorse"
    "dpflug"
)

##################################################

ARGS=$(getopt -o "hnto::" -l "help,noop,no-op,test,offset::" -n "$0" -- "$@");
echo "$ARGS"
eval set -- "$ARGS"
OFFSET=0

while true; do
    case "$1" in
	-h|--help)
	    shift
	    echo "Usage: mail_changer.sh [-t] [-oOFFSET]"
	    echo -e "  Arguments:"
	    echo -e "    -t, --test\t\t\tOutput a 10 day period (optionally, around offset) for testing."
	    echo -e "    -oOFFSET, --offset=OFFSET\tNumber of hours (positive or negative) to offset."
	    exit
	    ;;
	-n|--noop|--no-op)
	    shift
	    NOOP=1
	    ;;
	-t|--test)
	    shift
	    TEST=1
	    ;;
	-o|--offset)
	    shift
	    # Sanitize input
	    case "${1#[-+]}" in
		''|*[!0-9]*)
		    echo "ERROR: Offset must be an integer."
		    exit
		    ;;
		*)
		    OFFSET="$1"
		    ;;
	    esac
	    shift
	    ;;
	--)
	    shift
	    break
	    ;;
	*)
	    echo "Internal error!"
	    exit
	    ;;
    esac
done


set_vars() {
    # Two shifts/day, minus one default recipient
    SHIFT_COUNT=$(( (${#DESK_JOCKEYS[@]} - 1) / 2))
    # Epoch was a Thursday, so add 3 days to make it Sunday, then divide by seconds in a week
    WEEK=$((($(date +%s --date="$1") - 259200) / 604800))
    # I'm doing the modulo 6 to get 0s on the weekends to trigger default behavior
    DOW=$(($(date +%w --date="$1") % 6))
    if [ "$DOW" -eq 0 ] ; then
	# Weekend; use default
	SHIFT=0
    else
	# Which day of the cycle is it?
	DAY=$(( $(date +%w --date="$1") + (WEEK % SHIFT_COUNT) * 5 ))
	# Is it after SHIFT_CHANGE?
	SHIFT_OFFSET=$(( ($(date +%k%M --date="$1") < SHIFT_CHANGE)?0:1 ))
	# Is it after SHIFTS_END?
	AFTER_HOURS=$(( ($(date +%k%M --date="$1") < SHIFTS_END)?0:1 ))
	# Pick our shift from the list
	SHIFT=$(( AFTER_HOURS?0:((DAY % SHIFT_COUNT) * 2 + 1 + SHIFT_OFFSET) ))
    fi
}

if [ "$TEST" == 1 ] ; then
    for d in {-5..5} ; do
	for t in "0000" "$SHIFT_CHANGE" "$SHIFTS_END" ; do
	    when="+ $d days $t + $OFFSET hours"
	    set_vars "$when"
	    
	    echo "$(date --date="$when")" "-- ${DESK_JOCKEYS[$SHIFT]}"
	done
    done
else
    set_vars "+ $OFFSET hours"
    setmail "${DESK_JOCKEYS[$SHIFT]}"
fi
