#!/bin/bash
# Author: David Pflug (dpflug@circuit5.org)
# Intended to be used via cron at midnight and 12:30, but can be run any time
# Assumes 2 shifts per day
# Likely won't last that long, but affected by the year 2038 problem.

setmail() {
    # Called with username to email to
    # TODO
    #### YOU PROBABLY NEED TO CHANGE THIS ####
    echo "User: $1"
    #sed "s/helpdesk-usa:.*/helpdesk-usa: $user/"
    #newaliases
    #/etc/init.d/postfix reload
}

SHIFT_CHANGE=1230
DESK_JOCKEYS=(
    "court_technology_department"
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

WEEK=$(($(date +%s) / 604800)) # Get current week from epoch
# I'm doing the modulo 6 to get 0s on the weekends to trigger default behavior
DAY=$(($(date +%w) % 6 * (WIC + 1))) # Day of cycle
WEEKDAY_FROM_EPOCH=$(( (DAY==0)?0:(WEEK * 5 + DAY)))
SHIFT_OFFSET=$(( ($(date +%H%M) <= SHIFT_CHANGE)?0:1 ))
UNADJUSTED_SHIFT=$(( WEEKDAY_FROM_EPOCH % ((${#DESK_JOCKEYS[@]}-1) / 2) ))
SHIFT=$(( (DAY==0)?0:(UNADJUSTED_SHIFT * 2 + 1 + SHIFT_OFFSET) ))

setmail ${DESK_JOCKEYS[$SHIFT]}
