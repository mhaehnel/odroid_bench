#!/bin/bash

[[ $0 =~ all_cpus.sh$ ]] && find /sys/devices/system/cpu -maxdepth 1 -mindepth 1 -name 'cpu?' -type d && exit

for i in $(find /sys/devices/system/cpu -maxdepth 1 -mindepth 1 -name 'cpu?' -type d); do
	if [[ $0 =~ big_cpus.sh$ ]]; then
		[ $(cat $i/of_node/compatible) == "arm,cortex-a15" ] && echo $i;
	elif [[ $0 =~ little_cpus.sh$ ]]; then
		[ $(cat $i/of_node/compatible) == "arm,cortex-a7" ] && echo $i;
	else
		echo "UNKNOWN CPU TYPE!"
	fi
done
