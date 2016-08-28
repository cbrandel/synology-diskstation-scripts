#!/bin/sh
ADMIN_DIR=$(dirname "$(readlink -f "$0")")
. "$ADMIN_DIR/settings"
ZoneRootDir=/var/packages/DNSServer/target
ZonePath=$ZoneRootDir/named/etc/zone/master
LOGFILE=/var/log/synolog/synosys.log
ret=0

DHCP_TIME=$(date -d "$(stat /etc/dhcpd/dhcpd-leases.log | grep Modify | cut -d ' ' -f 2-)" "+%s")
DNS_TIME=$(date -d "$(stat $ZonePath/$ForwardMasterFile | grep Modify | cut -d ' ' -f 2-)" "+%s")
if [ $DHCP_TIME -gt $DNS_TIME ]
then
  echo "dhcp leases changed - reloading DNS"
  $ADMIN_DIR/diskstation_dns_modify.sh
  ret=$?
  ts=$(date "+%Y/%m/%d %H:%M:%S")
  if [ "$ret" -eq "0" ]
  then
    printf "info\t%s\tSYSTEM:\tUpdated DNS from DHCP.\n" "$ts" >> $LOGFILE
  else
    printf "err\t%s\tSYSTEM:\tError Updating DNS from DHCP. Code: [%s].\n" "$ts" "$ret" >> $LOGFILE
  fi
fi
exit $ret
