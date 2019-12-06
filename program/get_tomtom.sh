#!/bin/bash
cores=8
dir=$1
#mkdir tomtom
species=$(head -n 1 species_main.txt)
files="$(find $dir -maxdepth 2 -name "*.meme" -print)"
echo "$files"
for file in $files ;
do
	while :; do
    background=( $(jobs -p))
    if (( ${#background[@]} < cores )); then
        break
    fi 
    sleep 1
	done
	mkdir tomtom/$(basename "$file" .fsa.meme)
	if [ "$species" == "Human" ]; then
	nohup /var/www/html/iris3/program/meme/bin/tomtom  -no-ssc -oc tomtom/$(basename "$file" .fsa.meme)/ -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 0.05 $file /var/www/html/iris3/program/motif_databases/HUMAN/HOCOMOCOv11_full_HUMAN_mono_meme_format.meme &
	fi
	if [ "$species" == "Mouse" ]; then
	nohup /var/www/html/iris3/program/meme/bin/tomtom  -no-ssc -oc tomtom/$(basename "$file" .fsa.meme)/ -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 0.05 $file /var/www/html/iris3/program/motif_databases/MOUSE/HOCOMOCOv11_full_MOUSE_mono_meme_format.meme &
fi
done
wait


