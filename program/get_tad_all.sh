#!/bin/bash

# 
dir=/var/www/html/iris3/program/db/tad/mm10
#dir=/var/www/html/iris3/program/tad/hg38

files="$(find $dir -maxdepth 2 -name "*.domains" -print)"
bed_files="$(find $atac_dir -maxdepth 2 -name "*.bed" )"
#echo $bed_files
for file in $files
do
	bedtools intersect -a $file -b /var/www/html/iris3/program/db/mouse_gene_info.bed -wa -wb > $file.bed 
done

