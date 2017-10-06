#!/bin/bash
startt=`date +%s%N`
endt=$(echo $startt+$1*1000000000 | bc -l)
while [ `date +%s%N` -lt  $endt ]; do 
	true;
done
