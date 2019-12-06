#!/bin/bash
cores=8
dir=$1
mkdir tomtom
perl /var/www/html/iris3/program/dminda/motif_tools/bobro2align.pl $dir
files="$(find $dir -maxdepth 2 -name "*b2a" -print)"
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
	
	perl /var/www/html/iris3/program/dminda/motif_tools/split_multifasta.pl -i $file -o $dir\/logo &
done
wait



files="$(find $dir -maxdepth 2 -name "*.fsa" -print)"
$count = 0
for file in $files ;
do
	while :; do
    background=( $(jobs -p))
    if (( ${#background[@]} < cores )); then
        break
    fi
    sleep 1
	done
	#if grep -q $(basename "$file" .fsa) "total_motif_list.txt"; then
	echo "$count"
	$count = $count + 1
	perl /var/www/html/iris3/program/dminda/motif_tools/align2uniprobe.pl $file | perl /var/www/html/iris3/program/dminda/motif_tools/uniprobe2meme > $file.meme &
	#mkdir tomtom/$(basename "$file" .fsa)
	#mkdir tomtom/$(basename "$file" .fsa)/HOCOMOCO
	#mkdir tomtom/$(basename "$file" .fsa)/JASPAR
	#/var/www/html/iris3/program/meme/bin/tomtom  -no-ssc -oc tomtom/$(basename "$file" .fsa)/HOCOMOCO -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 10.0 $file.meme /var/www/html/iris3/program/motif_databases/HUMAN/HOCOMOCOv11_full_HUMAN_mono_meme_format.meme /var/www/html/iris3/program/motif_databases/MOUSE/HOCOMOCOv11_full_MOUSE_mono_meme_format.meme 
	#/var/www/html/iris3/program/meme/bin/tomtom  -no-ssc -oc tomtom/$(basename "$file" .fsa)/JASPAR -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 10.0 $file.meme /var/www/html/iris3/program/motif_databases/JASPAR/JASPAR2018_CORE_non-redundant.meme /var/www/html/iris3/program/motif_databases/JASPAR/JASPAR2018_CORE_vertebrates_non-redundant.meme 
	
	#echo "/var/www/html/iris3/program/meme/bin/tomtom  -no-ssc -oc tomtom/$(basename "$file" .fsa)/HOCOMOCO -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 10.0 $file.meme /var/www/html/iris3/program/motif_databases/HUMAN/HOCOMOCOv11_full_HUMAN_mono_meme_format.meme /var/www/html/iris3/program/motif_databases/MOUSE/HOCOMOCOv11_full_MOUSE_mono_meme_format.meme "
	tail -n +2 $file > $file.logo.fa &
	perl /var/www/html/bobro2/program/script/weblogo/seqlogo -F PNG -a -n -Y -k 1 -c  -f $file.logo.fa > $file.png &
	#fi
done
wait


