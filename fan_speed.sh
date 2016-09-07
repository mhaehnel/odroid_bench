#!/bin/sh

for i in /sys/class/thermal/thermal_zone?; do
	echo user_space >$i/policy
	echo disabled >$i/mode
done

echo $1 >/sys/class/thermal/cooling_device0/cur_state
