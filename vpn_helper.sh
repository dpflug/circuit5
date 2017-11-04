#!env bash
if [[ "$1" =~ "Enter password for dpflug@marvpn.circuit5.org:" ]] ; then
    su - dpflug -c "pass show Work | head -n1"
elif [[ "$1" =~ "Enter IPSec secret for c5users@marvpn.circuit5.org:" ]] ; then
    su - dpflug -c "pass show VPN | head -n1"
else
    >&2 echo "Unknown password: $1"
fi
