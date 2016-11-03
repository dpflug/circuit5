#!/bin/bash
# IP hasn't been available lately?
#IPHALF="${IP%.*.*}"
#SECOND_OCTET="${IPHALF#*.}"

log="/home/dpflug/CONNECT_C5"

{ echo "=======";
  echo "$ACTION - $SSID";
  date; } >> $log

if [ "$SSID" = "C5" ] || [ "$SSID" = "C5ENT" ] || [ "$SSID" = "" ] ; then
    su - dpflug /home/dpflug/bin/connect_c5.sh || true
    SECOND_OCTET="$(ip a | grep -oP '(?<=\b10.)1\d{2,3}(?=.\d{1,3}.\d{1,3}/)' | head -n1)"
    echo "Starting octet match." >> $log
    echo "Second octet: $SECOND_OCTET" >> $log
    #if [ "$Profile" = "wlp3s0-C5" ] ||
    #       [ "$Profile" = "wlp3s0-C5ENT" ] ||
    #       [ "$Profile" = "eno1-dhcp" ] && [ "${IP%.*.*.*}" = "10" ] ; then
    if [ "$SECOND_OCTET" = 128 ] ; then
	# In Citrus
	COUNTY="cit"
    elif [ "$SECOND_OCTET" = 129 ] ; then
	# In Hernando
	COUNTY="her"
    elif [ "$SECOND_OCTET" = 130 ] ; then
	# In Lake
	COUNTY="lak"
    elif [ "$SECOND_OCTET" = 131 ] ; then
	# In Marion
	COUNTY="mar"
    elif [ "$SECOND_OCTET" = 132 ] ; then
	# In Sumter	
	COUNTY="sum"
    fi
    #fi
else
    su - dpflug /home/dpflug/bin/connect_other.sh
fi

if [ "$COUNTY" ] ; then
    sed -i.bk 's/#include/include/' /etc/unbound/unbound.conf
    sed -i.bk -e "/cache_peer/s/[a-z]*proxy/${COUNTY}proxy/" \
	-e 's/#cache_peer/cache_peer/' \
	-e 's/#never_direct/never_direct/' \
	/etc/squid/squid.conf
    systemctl reload unbound squid
else
    echo "No county detected." >> $log
    sed -i.bk 's/ include/ #include/' /etc/unbound/unbound.conf
    sed -i.bk -e 's/^cache_peer/#cache_peer/' \
	-e 's/^never_direct/#never_direct/' \
	/etc/squid/squid.conf
    systemctl reload unbound squid
fi
