#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 

[[ $0 =~ _big.sh ]] && CPUS=$($DIR/big_cpus.sh)
[[ $0 =~ _little.sh ]] && CPUS=$($DIR/little_cpus.sh)
if [[ $0 =~ _all.sh ]]; then
	if [[ $0 =~ disable_ ]]; then
		echo "Disabling all CPUS makes no sense .. bailing"
		exit -1
	fi
	CPUS=$($DIR/all_cpus.sh)
fi

[[ $0 =~ enable_ ]] && SET=1
[[ $0 =~ disable_ ]] && SET=0
[[ -z "${SET}" ]] && echo "Unknown operation! enable / disable supported only." && exit

for i in $CPUS; do
	echo ${SET} >$i/online
done
