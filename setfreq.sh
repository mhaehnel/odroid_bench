#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[[ $0 =~ _big.sh ]] && CPUS=$($DIR/big_cpus.sh | head -n1)
[[ $0 =~ _little.sh ]] && CPUS=$($DIR/little_cpus.sh | head -n1)
[[ $0 =~ _all.sh ]] && CPUS=$($DIR/big_cpus.sh | head -n1; $DIR/little_cpus.sh | head -n1 )

[[ $0 =~ _min_ ]] && SET=min
[[ $0 =~ _max_ ]] && SET=max
[[ -n "$1" && -n ${SET} ]] && echo "Can only set to value OR to min/max. Not both!" && exit
[[ -z "${SET}" && -z "$1" ]] && echo "Unknown operation! min / max / param supported only." && exit
[[ -z "${SET}" ]] && SET=$1

for i in $CPUS; do
	echo "userspace" >$i/cpufreq/scaling_governor
	FREQ=$SET
	CURFREQ=$(cat $i/cpufreq/scaling_cur_freq)
	if [ $SET == "min" ]; then
		FREQ=$(cat $i/cpufreq/cpuinfo_min_freq)
	elif [ $SET == "max" ]; then
		FREQ=$(cat $i/cpufreq/cpuinfo_max_freq)
	fi
	echo "${FREQ} for CPU $i"
	if [ ${FREQ} -lt ${CURFREQ} ]; then
		echo ${FREQ} >$i/cpufreq/scaling_min_freq
		echo ${FREQ} >$i/cpufreq/scaling_max_freq
	else
		echo ${FREQ} >$i/cpufreq/scaling_max_freq
		echo ${FREQ} >$i/cpufreq/scaling_min_freq
	fi
	echo ${FREQ} >$i/cpufreq/scaling_setspeed
done
