#!/bin/sh

TEMP=40

##### END CONFIGURATION ######

let ACTUAL_TEMP=TEMP*1000

echo "Cooling down to $ACTUAL_TEMP ..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$DIR/setfreq_min_all.sh

#for i in $(find /sys/devices/system/cpu -maxdepth 1 -mindepth 1 -name 'cpu?' -type d); do
#	echo "Setting $i";
#	echo userspace >$i/cpufreq/scaling_governor
#	echo $(cat $i/cpufreq/cpuinfo_min_freq) >$i/cpufreq/scaling_setspeed
#done

$DIR/fan_speed.sh $(cat /sys/class/thermal/cooling_device0/max_state)
while [ $(cat /sys/class/thermal/thermal_zone0/temp) -gt ${ACTUAL_TEMP} ];  do
#	/root/tools/fan_speed.sh 3
	sleep 1;
done

echo "It's cool!"	
