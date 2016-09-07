#!/bin/sh

for i in /sys/bus/i2c/devices/0-004*; do
	echo 0 >$i/enable
	echo 1 >$i/enable
done

[ -z "${EVS}" ] && EVS=cycles,bus-cycles,instructions,cache-misses,cache-references,task-clock
perf stat -e $EVS "$@" >/dev/null

for i in /sys/bus/i2c/devices/0-004*; do
	echo "E_$(cat $i/sensor_name): $(cat $i/sensor_J)" >&2
	echo 0 >$i/enable
done
