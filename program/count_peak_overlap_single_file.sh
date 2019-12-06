#!/bin/bash
# input: workdir CT1S-R1 human
# 
dir=$1
file=atac/$2.bed
species=$3
if [ "$species" == "Human" ]; then
atac_dir=/var/www/html/iris3/program/db/human_atac_seq
atac_summary=/var/www/html/iris3/program/db/human_atac_seq/human_atac_data.txt
fi
if [ "$species" == "Mouse" ]; then
atac_dir=/var/www/html/iris3/program/db/mouse_atac_seq
atac_summary=/var/www/html/iris3/program/db/mouse_atac_seq/mouse_atac_data.txt
fi

#files="$(find $dir -maxdepth 2 -name "*.regulon_motif.txt" -print)"
bed_files="$(find $atac_dir -maxdepth 2 -name "*.bed" | sort -nr)"
> atac/$2.atac_overlap.txt
total_regulon_gene="$(cat $file | awk -F '\t' '{print $4}'  | sort | uniq -c | sort -nr| wc -l)"
for atac_bed in $bed_files
do
	overlap_gene="$(bedtools intersect -a $file -b $atac_bed | awk -F '\t' '{print $4}'  | sort | uniq -c | sort -nr| awk -F ' ' '{print $2}')"
	total_overlap_gene="$(bedtools intersect -a $file -b $atac_bed | awk -F '\t' '{print $4}'  | sort | uniq -c | sort -nr| wc -l)"
	overlap_percent="$(echo "scale=3;$total_overlap_gene/$total_regulon_gene"|bc -l|sed -E 's/(^|[^0-9])\./\10./g')"
	#overlap_percent="$(echo $overlap_percent%)"
	#echo "$overlap_percent"
	echo -e $overlap_percent"\t"$total_overlap_gene"\t"$overlap_gene >> atac/$2.atac_overlap.txt
done

paste atac/$2.atac_overlap.txt $atac_summary |awk -F $'\t' -v OFS='\t' '{print $4,$6,$2,$1,$5,$7,$8,$3}'>  atac/$2.atac_overlap_result.txt

## count # of peaks
#for atac_bed in $bed_files
#do
#	#echo "$atac_bed"
#	awk -v str="[0-9]" '$1 == str' $atac_bed 
#done
# 
