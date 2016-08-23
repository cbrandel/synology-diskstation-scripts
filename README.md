synology-diskstation-scripts
============================

Scripts that help with Synology Diskstation maintenance

Adapted from: https://github.com/gclayburg/synology-diskstation-scripts

# Why do I need this?

## tl;dr version:  
You are running Synology Diskstation DNS and DHCP services and you want dynamic DHCP reservations to update DNS immediately.

## Background
Synology Diskstation has an embedded DNS server that can be enabled for your network.  This does the standard thing of resolving hostnames to IP addresses.  So, lets say you have a VMware ESXi server on your local network. You arbitrarily name it `esxi1.homelan.net`.   The DNS server is where you map the name `esxi1.homelan.net` to the static IP address of `192.168.1.10`.  From then on, all other devices in your network can access this server using the name `esxi.homelan.net`.  Only the DNS server needs to remember the IP address.  Nothing new here.

Synology diskstation also has a DHCP server that you can use to dynamically assign IP addreses to hosts on your network.  This means you can power up a new laptop, ipad, or guest VM on your network and it will be able to use the network without configuring anything.  Under the covers, they use DHCP to get an available IP address from your DHCP server.

Synology can host both of these services and they both work well by themselves.  However, they don't talk to each other.  They both deal with IP addresses and hostnames, yet they operate independently.  For example, when you power on your laptop, the laptop will essentially say something like this:  "Hello, my hostname is `garylaptop` and I need an available IP address".  The DHCP server will gladly assign an unused IP address, but that is where things end.  The DNS server knows nothing about this hostname to IP address assignment.  This means that no other host on the network will be able to refer to the laptop if they only know the hostname.  You can't, for example, do something like `ssh garylaptop` from another host on your network.

For the average consumer client device like a laptop or ipad, this is normally fine.  It is unlikely that other devices on the network want to communicate with the laptop using a hostname.

This becomes more of an issue when you have more devices and servers running on your network.  The default for most new servers and clients is to use DHCP to get an IP address.  This makes things simpler for setting up that new linux distribution, but gets in the way when you want to experimient with some server software on there.  One approach is to manually assign a static IP address and create a static DNS entry for this new server.  This is something you would want to do if you know you want to keep that server around for a while.  But if you are just messing around with something new, it is quite handy to have all of this taken care of for you.  This is where this project comes in.

## diskstation_dns_modify.sh

This script can be used to configure a synology diskstation to automatically update its internal DNS records from its internal DHCP server.  As of 2014-10-20 Synology Diskstation DSM cannot do this from the GUI.

### Credit

The script originated from Tim Smith here:

http://forum.synology.com/enu/viewtopic.php?f=233&t=88517

Original docs:

https://www.youtube.com/watch?v=T22xytAWq3A&list=UUp8GcSEeUnLY8d6RAT6Y3Mg

This is a fork of gclayburg

https://github.com/gclayburg/synology-diskstation-scripts

Writing Synology syslog entries

https://forum.synology.com/enu/viewtopic.php?f=27&t=6396

### changelog

pre 2016-08-23 see https://github.com/gclayburg/synology-diskstation-scripts/blob/master/README.md

2016-08-23  Fork from gclayburg's version and chagnes:

* Scripts auto detect the directory they are run from.
* poll-dhcp-changes script also uses settings file to determine some filenames
* poll-dhcp-changes compares timestamp of dhcp leases and dns master file
* script can be run from Synology scheduled task (runs only every minute, but that's enough for me) -  eliminates the need for start scripts
* removed S99pollDHCP.sh and startDHCP-DNS.sh as they are not needed for running periodically as scheduled task
* adapted deployment documentation

# Deployment

You will need to:

1. Install two scripts into the "admin" account.  These scripts should be owned by root and executable:

    ```
    DiskStation> ls -l /var/services/homes/admin/*sh
    -rwxr-xr-x    1 root     root          7798 May  1 15:07 /var/services/homes/admin/diskstation_dns_modify.sh
    -rwxr-xr-x    1 root     root           283 Nov 21  2014 /var/services/homes/admin/poll-dhcp-changes.sh
    ```
   These scripts do not need to be modified.

2. Install the settings file in the same directory as the script files:

    ```
    DiskStation> ls -l /var/services/homes/admin/settings                              
    -rw-r--r--    1 root     root           109 Sep 24  2015 /var/services/homes/admin/settings
    ```

    The settings file needs to be modified to match your network.  See the comments in the `diskstation_dns_modify.sh` script for details.

## Periodically running via Task Scheduler
1.  Open Task Scheduler
2.  Click Create -> Scheduled Task -> User-defined script
3.  Key in a name for the task.  Anything is fine here.
4.  Check the "Enabled" button.
5.  Choose user "root"
6.  On the schedule tab set the schedule to "Daily", first runtime to 00:00, frequency to "every  1 minute", last runtime to 23:59
7. On the task settings tab Key in this in the User-defined script area and click OK:
```sh
        /var/services/homes/admin/poll-dhcp-changes.sh
```
(or wherever you put the script).
8. Optionally have the task send an email upon failure.

## Troubleshooting

Each time this script detects that that there is a DHCP change, DNS will be updated.  It may take up to 1-2 minutes for DNS to be updated after a new DHCP reservation. When DNS is updated or when an error occurs an entry is added to the Synology logs which can be seen in Log Center.  

You can also view the DNS log from the normal DSM UI.  This can be useful if there is some sort of conflict between static DNS entries that you defined in the DSM DNS UI and new DHCP hostnames.
