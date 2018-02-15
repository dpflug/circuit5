#!/bin/bash

usage () {
    echo "Usage: rtonduty_exception.sh USERNAME TIMESPEC"
    echo ""
    echo "  The username has to have a postfix virtual file in /etc/postfix."
    echo "  TIMESPEC is parsed by at(1), so check its manpage for details, but the following all work:"
    echo "    12:31"
    echo "    14:00 tomorrow"
    echo "    11AM Wednesday"
    echo "    8:01 July 22 2022"
}

# Parse/verify arguments
if (( $# < 2 )) ; then
    usage
    exit
fi
while true ; do
    case "$1" in
        -h|--help)
            usage
            exit
            ;;
        --)
            shift
            break
            ;;
        *)
            if [ -z ${RECIPIENT+x} ] ; then
                RECIPIENT="$1"
                shift
            else
                TIMESPEC="$@"
                break
            fi
            ;;
    esac
done
if [[ ! -f "/etc/postfix/virtual.$RECIPIENT" ]]; then
    echo "ERROR: That RECIPIENT doesn't have a postfix virtual file! Exiting."
    echo ""
    usage
    exit 1
fi

# at will tell us when the command is scheduled. I'm echoing runcmd so we know for sure what's being run.
runcmd="/adm/bin/rtonduty_change.sh $RECIPIENT | mail -s \"Setting $RECIPIENT onduty for RT\" court_technology_department@circuit5.org"
echo "$runcmd" | at "$TIMESPEC" 2>&1 &&
echo "$runcmd"
