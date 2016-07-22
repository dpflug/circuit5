#!/bin/bash
# IP hasn't been available lately?
#IPHALF="${IP%.*.*}"
#SECOND_OCTET="${IPHALF#*.}"

log="/home/dpflug/CONNECT_C5"

{ echo "=======";
  echo "$ACTION - $SSID";
  date; } >> $log

if [ "$SSID" = "C5" ] || [ "$SSID" = "C5ENT" ] ; then
    su - dpflug /home/dpflug/bin/connect_c5.sh || true
    SECOND_OCTET="$(ip a | grep -oP '\b10.1\d{2,3}.\d{1,3}.\d{1,3}(?=/)')"
    echo "Starting octet match." >> $log
    { echo -n "Second octet: ";
      echo "$SECOND_OCTET"; } >> $log
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
fi

if [ "$COUNTY" ] ; then
    { echo -n "Detected county: ";
      echo "$COUNTY"; } >> $log
    sed -i.bk 's/#include/include/' /etc/unbound/unbound.conf
    systemctl reload unbound
    sed -i.bk "/^Upstream/s/[a-z]*proxy/${COUNTY}proxy/" /etc/tinyproxy/tinyproxy.conf
    systemctl stop polipo tinyproxy
    sleep 2
    systemctl start tinyproxy
else
    echo "No county detected." >> $log
    sed -i.bk 's/ include/ #include/' /etc/unbound/unbound.conf
    systemctl reload unbound
    systemctl stop polipo tinyproxy
    sleep 2
    systemctl start polipo
fi
