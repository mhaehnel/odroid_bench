#!/bin/bash

for i in /sys/bus/i2c/devices/0-004*; do
	echo 0 >$i/enable
	echo 1 >$i/enable
done

~alarm/SmartDroid/smartdroid -a stop
~alarm/SmartDroid/smartdroid -a start

$@

echo -n "E_sensor_ext: "
echo `~alarm/SmartDroid/smartdroid -m energy`*3600 | bc -l
~alarm/SmartDroid/smartdroid -a stop


for i in /sys/bus/i2c/devices/0-004*; do
	echo "E_$(cat $i/sensor_name): $(cat $i/sensor_J)" >&2
	echo 0 >$i/enable
done

