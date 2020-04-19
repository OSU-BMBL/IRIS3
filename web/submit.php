<?php
// include "head.html";
set_time_limit(3000);
session_start();

require("config/common.php");
require("config/smarty.php");

$smarty->caching = true;
$smarty->assign('section', 'Homepage');
#$_SESSION['labelfile'] = '';
#$_SESSION['gene_module_file'] = '';

function get_client_ip_server() {
    $ipaddress = '';
    if ($_SERVER['HTTP_CLIENT_IP'])
        $ipaddress = $_SERVER['HTTP_CLIENT_IP'];
    else if($_SERVER['HTTP_X_FORWARDED_FOR'])
        $ipaddress = $_SERVER['HTTP_X_FORWARDED_FOR'];
    else if($_SERVER['HTTP_X_FORWARDED'])
        $ipaddress = $_SERVER['HTTP_X_FORWARDED'];
    else if($_SERVER['HTTP_FORWARDED_FOR'])
        $ipaddress = $_SERVER['HTTP_FORWARDED_FOR'];
    else if($_SERVER['HTTP_FORWARDED'])
        $ipaddress = $_SERVER['HTTP_FORWARDED'];
    else if($_SERVER['REMOTE_ADDR'])
        $ipaddress = $_SERVER['REMOTE_ADDR'];
    else
        $ipaddress = 'UNKNOWN';
 
    return $ipaddress;
}
function detectDelimiter($csvFile)
{
    $delimiters = array(
        ';' => 0,
        ',' => 0,
        "\t" => 0,
        "|" => 0,
		" " => 0,
    );

    $handle = fopen($csvFile, "r");
    $firstLine = fgets($handle);
    fclose($handle); 
    foreach ($delimiters as $delimiter => &$count) {
        $count = count(str_getcsv($firstLine, $delimiter));
    }

    return array_search(max($delimiters), $delimiters);
}
if (isset($_POST['submit']))
{
	session_start();
	file_put_contents("$BASE/ip.txt",PHP_EOL .get_client_ip_server(), FILE_APPEND | LOCK_EX);
	//$jobid = date("YmdGis");
	$jobid = $_SESSION['jobid'];
	
	$workdir = "./data/$jobid";
	mkdir($workdir);
	$is_imputation = $_POST['is_imputation'];
	$remove_ribosome = $_POST['remove_ribosome'];
	$is_c = $_POST['is_c'];
	if($is_imputation =="") {
		$is_imputation = '0';
	}
	if($is_c =="Yes") {
		$is_c = '-C';
	} else {
		$is_c = '';
	}
	$email = $_POST['email'];
	$c_arg = '1.0';
	$c_arg = '20';
	$f_arg = '0.5';
	$o_arg = '100';
	$resolution_seurat = $_POST['resolution_seurat'];
	$promoter_arg = '1000';
	$c_arg = $_POST['c_arg'];
	$f_arg = $_POST['f_arg'];
	$o_arg = $_POST['o_arg'];
	$k_arg = $_POST['k_arg'];
	$n_variable_features = $_POST['n_variable_features'];
	$n_pca = $_POST['n_pca'];
	$k_arg = $_POST['k_arg'];
	$is_load_exp = $_POST['is_load_exp'];
	$is_load_label = $_POST['is_load_label'];
	$is_load_gene_module = $_POST['is_load_gene_module'];
	$promoter_arg = $_POST['promoter_arg'];
	
	$species_arg=$_POST['species_arg'];
	#$fp = fopen("$workdir/species.txt", 'w');
	#fwrite($fp,"$species_arg");
	#fclose($fp);
	file_put_contents("$workdir/species.txt", implode(PHP_EOL, $species_arg));
	file_put_contents("$workdir/species.txt", "\n",FILE_APPEND);
	$expfile = $_SESSION['expfile'];
	$labelfile = $_SESSION['labelfile'];
	$gene_module_file = $_SESSION['gene_module_file'];
    if ($labelfile == '') {
		$label_use_predict = '0';
	} else {
		$label_use_predict = '2';
	}
	
	
	if($expfile=='iris3_example_expression_matrix.csv'){
		$fp = fopen("$workdir/upload_type.txt", 'w');
		fwrite($fp,"CellGene\n");
		fclose($fp);
	}
	if($expfile=='Zeisel_expression.csv'){
		$fp = fopen("$workdir/upload_type.txt", 'w');
		fwrite($fp,"CellGene\n");
		fclose($fp);
	}
	if($k_arg == '20' && $f_arg == '0.7' && $o_arg == '5000' && $label_use_predict == '2' && $is_imputation == 'No' && $remove_ribosome == "No" && $promoter_arg == '1000' && $n_pca == '10' && $n_variable_features == '5000' && $expfile=='Zeisel_expression.csv' && $labelfile == 'Zeisel_index_label.csv'){
		header("Location: results.php?jobid=2020041684528");
	}  else {
	system("touch $workdir/email.txt");
	#system("chmod 755 $workdir/email.txt");
	$fp = fopen("$workdir/email.txt", 'w');
	if($email == ""){
		$email = "flykun0620@gmail.com";
	}
    fwrite($fp,"$email");
    fclose($fp);

	$workdir2 = "./data/$jobid/";
	

	$delim = detectDelimiter("$workdir2/$expfile");
	if($delim=="\t"){
		$delim = "tab";
	} else if($delim==" "){
		$delim = "space";
	} else if($delim==";"){
		$delim = "semicolon";
	} else {
		$delim = ",";
	}
	$delim_label = detectDelimiter("$workdir2/$labelfile");
		if($delim_label=="\t"){
		$delim_label = "tab";
	}
	if($delim_label==" "){
		$delim_label = "space";
	}
	if ($gene_module_file != "") {
	$delim_gene_module = detectDelimiter("$workdir2/$gene_module_file");
	if($delim_gene_module=="\t"){
		$delim_gene_module = "tab";
	}
	if($delim_gene_module==" "){
		$delim_gene_module = "space";
	}
	}
	$fp = fopen("$workdir/info.txt", 'w');
	fwrite($fp,"is_load_exp,$is_load_exp\nk_arg,$k_arg\nf_arg,$f_arg\no_arg,$o_arg\nresolution_seurat,$resolution_seurat\nn_variable_features,$n_variable_features\nn_pca,$n_pca\nlabel_use_predict,$label_use_predict\nexpfile,$expfile\nlabelfile,$labelfile\ngene_module_file,$gene_module_file\nis_imputation,$is_imputation\nremove_ribosome,$remove_ribosome\nis_c,$is_c\npromoter_arg,$promoter_arg\nbic_inference,$label_use_predict");
	fclose($fp);
	$fp = fopen("$workdir/running_status.txt", 'w');
	fwrite($fp,"preprocessing");
	fclose($fp);
	$fp = fopen("$workdir2/qsub.sh", 'w');

	if ($labelfile == ''){
		$labelfile = '1';
		$delim_label = ',';
	}

fwrite($fp,"#!/bin/bash\n 
wd=$BASE/data/$jobid/
exp_file=$expfile
label_file=$labelfile
gene_module_file=$gene_module_file
jobid=$jobid
motif_min_length=12
motif_max_length=12
perl $BASE/program/prepare_email1.pl \$jobid\n
Rscript $BASE/program/genefilter.R \$jobid \$wd\$exp_file $delim \$label_file $delim_label $is_imputation $resolution_seurat $n_pca $n_variable_features $label_use_predict $remove_ribosome
echo gene_module_detection > running_status.txt\n
$BASE/program/qubic2/qubic -i \$wd\$jobid\_filtered_expression.txt -k $k_arg -o $o_arg -f $f_arg $is_c
for file in *blocks
do
grep Conds \$file |cut -d ':' -f2 >\"$(basename \$jobid\_blocks.conds.txt)\"
done
for file in *blocks
do
grep Genes \$file |cut -d ':' -f2 >\"$(basename \$jobid\_blocks.gene.txt)\"
done
Rscript $BASE/program/ari_score.R \$label_file \$jobid $delim_label $label_use_predict
echo gene_module_assignment > running_status.txt\n
Rscript $BASE/program/cts_gene_list.R \$wd \$jobid $promoter_arg $gene_module_file $delim_gene_module \n
echo motif_finding_and_comparison > running_status.txt\n
$BASE/program/get_motif.sh \$wd \$motif_min_length \$motif_max_length 1
Rscript $BASE/program/convert_meme.R \$wd \$motif_min_length
$BASE/program/get_motif.sh \$wd \$motif_min_length \$motif_max_length 0
wait
cd \$wd
#find -name '*' -size 0 -delete
Rscript $BASE/program/prepare_bbc.R \$jobid \$motif_min_length\n

mkdir tomtom
mkdir logo_tmp
mkdir logo
mkdir regulon_id
$BASE/program/get_logo.sh \$wd
$BASE/program/get_tomtom.sh \$wd
echo active_regulon_determination > running_status.txt\n
#Rscript $BASE/program/merge_bbc.R \$wd \$jobid \$motif_min_length\n
Rscript $BASE/program/merge_tomtom.R \$wd \$jobid \$motif_min_length\n
echo regulon_inference > running_status.txt\n
Rscript $BASE/program/sort_regulon.R \$wd \$jobid\n
$BASE/program/get_atac_overlap.sh \$wd
#cat *CT*.regulon_motif.txt > combine_regulon_motif.txt\n
Rscript $BASE/program/prepare_heatmap.R \$wd \$jobid $label_use_predict\n
Rscript $BASE/program/get_alternative_regulon.R \$jobid\n
Rscript $BASE/program/generate_rss_scatter.R \$jobid\n
Rscript $BASE/program/process_tomtom_result.R \$jobid\n 
mkdir json
$BASE/program/build_clustergrammar.sh \$wd \$jobid $label_use_predict\n

zip -R \$wd\$jobid '*.regulon_gene_id.txt' '*.regulon_gene_symbol.txt' '*.regulon_rank.txt' '*_silh.txt' '*umap_embeddings.txt' '*.regulon_activity_score.txt' '*_cell_label.txt' '*.blocks' '*_blocks.conds.txt' '*_blocks.gene.txt' '*_filtered_expression.txt' '*_gene_id_name.txt' '*_marker_genes.txt' 'cell_cluster_unique_diffrenetially_expressed_genes.txt' '*_combine_regulon.txt'\n
perl $BASE/program/prepare_email.pl \$jobid\n
echo 'finish'> done\n  
#chmod -R 755 .
");

	fclose($fp);
	session_destroy();
	#system("chmod -R 755 $workdir2");
	system("cp $workdir/../index.php $workdir");
  system("cd $workdir; nohup sh qsub.sh > output.txt &");
	##shell_exec("$workdir/qsub.sh>$workdir/output.txt &");
	#header("Location: results.php?jobid=$jobid");
	header("Location: results.php?jobid=$jobid");
		
	}

}else
{
	#print_r($BASE);
	$smarty->display('submit.tpl');
}



?> 

