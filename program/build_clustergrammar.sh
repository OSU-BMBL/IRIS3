#!/bin/bash
cores=6
dir=$1
jobid=$2
use_user_label=$3
files="$(find $dir -name "*.heatmap.txt")"
#echo "$files"
for file in $files ;
do
	while :; do
    background=( $(jobs -p))
    if (( ${#background[@]} < cores )); then
        break
    fi
    sleep 1
	done
	out="$(basename $file .heatmap.txt)"
	if [[ $out == *"S-R"* ]]; then
	python2.7 /var/www/html/iris3/program/clustergrammer/make_clustergrammer.py $file $out $dir $jobid 0 &
	#echo $file $out $dir $jobid $use_user_label
	else
    python2.7 /var/www/html/iris3/program/clustergrammer/make_clustergrammer.py $file $out $dir $jobid $use_user_label &
	fi
done
wait
