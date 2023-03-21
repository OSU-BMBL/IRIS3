#!/bin/bash
cores=20
dir=$1
min_length=$2
max_length=$3
is_meme=$4
files="$(find $dir -maxdepth 2 -name "bic*fa" -print)"
meme_index="$(find $dir -maxdepth 2 -name "bic*fa" -print|wc -l)"
meme_index=$((meme_index+10))
echo "$files"
while read -r species; do 
	for file in $files ;
	do
		while :; do
		background=( $(jobs -p))
		if (( ${#background[@]} < cores )); then
			break
		fi
		sleep 1
		done
		ct_dir=$(dirname "${file}")
		if [ "$is_meme" == "1" ]; then
			#/var/www/html/iris3/program/meme/bin/meme $file -nostatus -w 12 -allw -mod anr -revcomp -nmotifs 10 -objfun classic -dna -text > $ct_dir"/bic"$meme_index.txt.fa.closures &
			/var/www/html/iris3/program/meme/bin/meme $file -nostatus -w 12 -allw -mod anr -revcomp -nmotifs 3 -objfun de -neg /var/www/html/iris3/program/bg_data/$species.bg.fa -dna -text > $ct_dir"/bic"$meme_index.txt.fa.closures &
			meme_index=$((meme_index+1))
		else
			cp $file $ct_dir"/bic"$meme_index.txt.fa
			meme_index=$((meme_index+1))
			/var/www/html/iris3/program/dminda/src/BoBro/BoBro -i $file -l $min_length -F -o 3 -Z /var/www/html/iris3/program/bg_data/$species.bg.fa &
		fi
		#perl /var/www/html/iris3/program/dminda/BBR1.pl 1 $file -L $min_length -U $max_length -R 2 -F -n 10 0.4
	done
done < $dir/species.txt
wait
