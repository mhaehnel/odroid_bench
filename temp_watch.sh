#!/bin/bash

THRESHOLD_TEMP=105


#### End Config ###

if [ $# -lt 2 ]; then
	echo "call with $0 <logname> <programname>"
	exit -1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CORESCRIPT=$DIR/all_cpus.sh
[[ $0 =~ _big.sh ]] && CORESCRIPT=$DIR/big_cpus.sh
[[ $0 =~ _little.sh ]] && CORESCRIPT=$DIR/big_cpus.sh
CORES=$(${CORESCRIPT} | grep -o '[0-9]*$' | paste -s -d, -)
OTHER=$(comm <($DIR/all_cpus.sh | sort) <($CORESCRIPT | sort) -3 | grep -o '[0-9]*$' | paste -s -d, -)
if [ -z "$OTHER" ]; then
	echo "WARNING: No dedicated script core";
fi

let ACTUAL_TEMP=THRESHOLD_TEMP*1000
LOGFILE=$1
shift
echo "Executing: $@" >$LOGFILE
paste -d, /sys/class/thermal/thermal_zone?/type >>$LOGFILE
[ -z "${EVS}" ] && EVS=cycles,instructions,cache-misses,cache-references,task-clock

taskset -c -p ${OTHER} $$
{ coproc fun { exec perf stat -e $EVS -o tmpfile taskset -c ${CORES} "$@"; } >&3; } 3>&1
PGRP=$$

if true; then
echo "COPROC_PID=$fun_PID"
echo "PGRP=$PGRP"
echo "Events: ${EVS}"
echo "Threshold: ${ACTUAL_TEMP}"
echo "Corescript: $CORESCRIPT"
echo "Pinning tasks to: $CORES"
echo "Pinning script to: $OTHER"
fi

for i in /sys/bus/i2c/devices/0-004*; do
	echo 0 >$i/enable
	echo 1 >$i/enable
done

while true; do
	if [ $(cat /sys/class/thermal/thermal_zone?/temp | sort -hr | head -n1) -gt ${ACTUAL_TEMP} ]; then
		echo "Thermal exception!" >>$LOGFILE
		#Kill all except self
		for i in `pgrep --pgroup $PGRP`; do
			[[  $i -eq $$ || $i -eq $fun_PID ]] && continue;
			kill $i
		done
		#Emergency cool!
		/root/tools/fan_speed.sh 3
		break;
	else
		echo -n "$(date +%s%N)," >>$LOGFILE
		paste -d, /sys/class/thermal/thermal_zone?/temp >>$LOGFILE
	fi
	kill -s 0 $fun_PID 2>/dev/null || break
	sleep 0.1
done

for i in /sys/bus/i2c/devices/0-004*; do
	echo "E_$(cat $i/sensor_name): $(cat $i/sensor_J)" >&2
	echo 0 >$i/enable
done

sleep 2
cat tmpfile
