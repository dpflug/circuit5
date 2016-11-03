#!/bin/bash
# Author: David Pflug (dpflug@circuit5.org)
# Intended to be used via cron at 12:30 AM and PM, but can be run any time
# Assumes 2 shifts per day

setmail() {
    # Called with username

    #sed "s/helpdesk-usa:.*/helpdesk-usa: $user/"
    #newaliases
    #/etc/init.d/postfix reload

    if [ "$DEBUG" == 1 ] ; then
	echo "User: $1"
    else
	/adm/bin/rtonduty_change.sh "$1"
    fi
}

SHIFT_CHANGE=1230
DESK_JOCKEYS=(
    # First option is who to send to by default
    # We default to the entire Court Tech department
    "allcourttech"
    "reckelberry"
    "jkidd"
    "broberts"
    "kmorse"
    "rellerbee"
    "dpflug"
    "bconley"
    "jkidd"
    "reckelberry"
    "kmorse"
    "broberts"
    "rellerbee"
    "bconley"
    "dpflug"
)

##################################################

ARGS=$(getopt -o "hdto::" -l "help,debug,test,offset::" -n "$0" -- "$@");
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
	    echo -e "    -oOFFSET, --offset=OFFSET\tNumber of 12 hour periods (positive or negative) to offset."
	    exit
	    ;;
	-d|--debug)
	    shift
	    DEBUG=1
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
	DAY=$(( $(date +%w --date="$1") + (WEEK % SHIFT_COUNT) * 5 )) # Day of cycle
	SHIFT_OFFSET=$(( ($(date +%k%M --date="$1") < SHIFT_CHANGE)?0:1 ))
	SHIFT=$(( (DAY % SHIFT_COUNT) * 2 + 1 + SHIFT_OFFSET ))
    fi
}

if [ "$TEST" == 1 ] ; then
    for i in {-10..10} ; do
	when="+ $(((OFFSET + i) * 12)) hours"
	set_vars "$when"
	    
	echo "$(date --date="$when")" "-- ${DESK_JOCKEYS[$SHIFT]}"
    done
else
    set_vars "+ $((OFFSET * 12)) hours"
    setmail "${DESK_JOCKEYS[$SHIFT]}"
fi
