#!/bin/bash
# Author: David Pflug (dpflug@circuit5.org)
# Intended to be used via cron at midnight and 12:30, but can be run any time
# Assumes 2 shifts per day
# Likely won't last that long, but affected by the year 2038 problem.

setmail() {
    # Called with username
    # TODO
    #### YOU NEED TO CHANGE THIS ####
    echo "User: $1"
    #sed "s/helpdesk-usa:.*/helpdesk-usa: $user/"
    #newaliases
    #/etc/init.d/postfix reload
}

SHIFT_CHANGE=1230
DESK_JOCKEYS=(
    "court_technology_department" # Who to send it to by default
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

if [ "$1" == "test" ] ; then
    for d in {-5..5} ; do
	for t in "0000" "$SHIFT_CHANGE"; do
	    when="+ $d days $t"
	    set_vars "$when"
	    
	    echo "$(date --date="$when")" "-- ${DESK_JOCKEYS[$SHIFT]}"
	done
    done
else
    set_vars "$(date)"
    setmail "${DESK_JOCKEYS[$SHIFT]}"
fi
