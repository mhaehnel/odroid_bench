#!/bin/bash

THRESHOLD_TEMP=115
SAMPLE_INTERVAL=1

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
echo "timestamp" | paste -d, /sys/class/thermal/thermal_zone?/type /sys/bus/i2c/devices/0-004?/sensor_name >>$LOGFILE
[ -z "${EVS}" ] && EVS=cycles,instructions,cache-misses,cache-references,task-clock
echo "Tracing Events: $EVS"
TMP=${EVS//[^,]}
TMP=${#TMP} 
echo "Event count: $TMP + 1"
COL_FILTER="1,2"
for i in `seq 1 $TMP`; do
	COL_FILTER="${COL_FILTER},$((i*8+2))"
done
echo "Col filter: $COL_FILTER"

taskset -c -p ${OTHER} $$


{ coproc fun { exec /usr/bin/time perf stat -x, -e $EVS -I 1000 "$@" 2>&1 >/dev/null | sed -u -e "$(printf 'N;%.0s' $(seq 1 $TMP))s/\n/,/g;s/ //g" | stdbuf -o0 cut -d, -f $COL_FILTER | tee -a ${LOGFILE}.perf_trace;} >&3; } 3>&1
PGRP=$$
if true; then
echo "COPROC_PID=$fun_PID"
echo "PGRP=$PGRP"
echo "Threshold: ${ACTUAL_TEMP}"
fi
echo "SampleTime,$EVS" | tee ${LOGFILE}.perf_trace

for i in /sys/bus/i2c/devices/0-004*; do
	echo 0 >$i/enable
	echo 1 >$i/enable
done

while true; do
	SDATE=$(date +%s)
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
		date +%s%N | paste -d,  - /sys/class/thermal/thermal_zone?/temp /sys/bus/i2c/devices/0-004?/sensor_J >>$LOGFILE
	fi
	kill -s 0 $fun_PID 2>/dev/null || break
	sleep ${SAMPLE_INTERVAL}
done

for i in /sys/bus/i2c/devices/0-004*; do
	echo "E_$(cat $i/sensor_name): $(cat $i/sensor_J)" >&2
	echo 0 >$i/enable
done



