#!/bin/bash

dir=$1

bbc_files="$(find $dir -maxdepth 1 -name "*CT*.bbc.txt" | sort -nr)"

cd $dir
> combine_bbc.bbc.txt
for file in $bbc_files
do
	bbcname=$(basename "$file")
	ctname="$(grep -oP '(?<=_).*?(?=_bic)' <<< $bbcname)"
	#echo $ctname
	head -n -1 $file > $file.tmp
	perl -pi -e "s/^>/>$ctname-/g" $file.tmp
done

cat *.bbc.txt.tmp > combine_bbc.bbc.txt
echo '>end' >> combine_bbc.bbc.txt
rm *.bbc.txt.tmp
files="$(find $dir -maxdepth 2 -name "20*.bbc.txt" -print)"
for file in $files ;
do
	fbname=$(basename "$file")
	perl /var/www/html/iris3/program/dminda/BBC.pl bg $fbname -1 0.4 0.8
done

#perl /var/www/html/iris3/program/dminda/BBC.pl bg combine_bbc.bbc.txt -1 0.4 0.8