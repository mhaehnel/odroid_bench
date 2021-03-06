#!/bin/bash

THRESHOLD_TEMP=115

#### End Config ###

if [ $# -lt 2 ]; then
	echo "call with $0 <logname> <programname>"
	exit -1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

let ACTUAL_TEMP=THRESHOLD_TEMP*1000
LOGFILE=$1
shift
echo "Executing: $@" >$LOGFILE
paste -d, /sys/class/thermal/thermal_zone?/type >>$LOGFILE
[ -z "${EVS}" ] && EVS=cycles,instructions,cache-misses,cache-references,task-clock

taskset -c -p ${OTHER} $$
{ coproc fun { LD_PRELOAD=~alarm/JPEG/tetris/lib/libtetrisclient.so exec /usr/bin/time "$@"; } >&3; } 3>&1
PGRP=$$

if true; then
echo "COPROC_PID=$fun_PID"
echo "PGRP=$PGRP"
echo "Threshold: ${ACTUAL_TEMP}"
fi

for i in /sys/bus/i2c/devices/0-004*; do
	echo 0 >$i/enable
	echo 1 >$i/enable
done

START=0
while [[ ${START} -lt 36000 ]]; do
	if [ $(cat /sys/class/thermal/thermal_zone?/temp | sort -hr | head -n1) -gt ${ACTUAL_TEMP} ]; then
		echo "Thermal exception!" >>$LOGFILE
		#Kill all except self
		for i in `pgrep --pgroup $PGRP`; do
			[[  $i -eq $$ || $i -eq $fun_PID ]] && continue;
			kill $i
		done
		#Emergency cool!
		break;
	else
		echo -n "$(date +%s%N)," >>$LOGFILE
		paste -d, /sys/class/thermal/thermal_zone?/temp >>$LOGFILE
	fi
	eval START=START+1
	kill -s 0 $fun_PID 2>/dev/null || break
	sleep 0.1
done
echo "Returned after: ${START} 1/10s"

for i in /sys/bus/i2c/devices/0-004*; do
	echo "E_$(cat $i/sensor_name): $(cat $i/sensor_J)" >&2
	echo 0 >$i/enable
done

