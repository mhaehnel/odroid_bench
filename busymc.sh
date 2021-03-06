#!/bin/bash

startt=`date +%s%N`
endt=$(echo $startt+$1*1000000000 | bc -l)
shift
taskset -c -p $1 $$
shift

#suppress coproc warning
exec 3>&2
exec 2>/dev/null

for c in $@; do
	coproc ( taskset -c $c sh -c 'while true; do true; done'; )
done
#Undo supression
exec 2>&3


while [ `date +%s%N` -lt  $endt ]; do 
	true;
done
pkill -P $$
