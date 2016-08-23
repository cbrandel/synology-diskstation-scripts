#!/bin/sh
ADMIN_DIR=$(dirname "$(readlink -f "$0")")
. "$ADMIN_DIR/settings"
ZoneRootDir=/var/packages/DNSServer/target
ZonePath=$ZoneRootDir/named/etc/zone/master
ret=0
# a bit clumsy, but this way the events will survive a firmware update
EVENTSFILE=/usr/syno/synosdk/texts/enu/events
if ! grep -q "90000000]" "$EVENTSFILE"; then
  cat >> "$EVENTSFILE" <<EOF
[90000000]
90000001 = "Updated DNS from DHCP."
90000002 = "Error Updating DNS from DHCP. Code: [@1]"
EOF
fi

DHCP_TIME=$(date -d "$(stat /etc/dhcpd/dhcpd-leases.log | grep Modify | cut -d ' ' -f 2-)" "+%s")
DNS_TIME=$(date -d "$(stat $ZonePath/$ForwardMasterFile | grep Modify | cut -d ' ' -f 2-)" "+%s")
if [ $DHCP_TIME -gt $DNS_TIME ]
then
  echo "dhcp leases changed - reloading DNS"
  $ADMIN_DIR/diskstation_dns_modify.sh
  ret=$?
  if [ "$ret" -eq "0" ]
  then
    synologset1 sys info 0x90000001
  else
    synologset1 sys err 0x90000002 $ret
  fi
fi
exit $ret
