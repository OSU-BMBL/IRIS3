<?php
	require("config/common.php");
	require("config/smarty.php");
	header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
	header("Cache-Control: post-check=0, pre-check=0", false);
	header("Pragma: no-cache");
#http://bmbl.sdstate.edu/CeRIS/prepare_tomtom.php?jobid=2018122581354&ct=6&bic=3&m=3&db=HOCOMOCO
require_once("config/common.php");
require_once("config/smarty.php");
require_once("lib/spyc.php");
//require_once("lib/hmmer.php");
$jobid = $_GET['jobid'];
$ct=$_GET['ct'];
$bic=$_GET['bic'];
$module=$_GET['module'];
$motif=$_GET['m'];
$db=$_GET['db'];
//$encodedString = json_encode($annotation1);
$done_file="a";
if(strlen($module) > 0){
	$motif_filename = "$BASE/data/$jobid/logo/$module"."bic$bic"."m$motif".".fsa.meme";
	$check_dir = "$BASE/data/$jobid/tomtom/module$module"."bic$bic"."m$motif"."/JASPAR/tomtom.html";
	if (!file_exists($check_dir)){
	header("Refresh: 1;url='prepare_tomtom.php?jobid=$jobid&ct=$ct&bic=$bic&m=$motif&db=$db'");
	#print_r ("start running");
	#mkdir ("$BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif");
	#mkdir ("$BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/HOCOMOCO");
	#mkdir ("$BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/JASPAR");
	#
	#$run_hoco = "nohup $BASE/program/meme/bin/tomtom  -no-ssc -oc $BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/HOCOMOCO -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 10.0 $motif_filename $BASE/program/motif_databases/HUMAN/HOCOMOCOv11_full_HUMAN_mono_meme_format.meme $BASE/program/motif_databases/MOUSE/HOCOMOCOv11_full_MOUSE_mono_meme_format.meme &";
	#$run_jas = "nohup $BASE/program/meme/bin/tomtom  -no-ssc -oc $BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/JASPAR -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 10.0 $motif_filename $BASE/program/motif_databases/JASPAR/JASPAR2018_CORE_non-redundant.meme $BASE/program/motif_databases/JASPAR/JASPAR2018_CORE_vertebrates_non-redundant.meme &";
	#
	#system($run_hoco);
	#system($run_jas);
	
}   else if (file_exists("$BASE/data/$jobid/tomtom/module$module"."bic$bic"."m$motif/$db")){
	$status = "0";
	header("Location: data/$jobid/tomtom/module$module"."bic$bic"."m$motif/$db/tomtom.html");
}	else {

	header("Refresh: 30;url='prepare_tomtom.php?jobid=$jobid&ct=$ct&bic=$bic&m=$motif&db=$db'");
}
} else {
	$motif_filename = "$BASE/data/$jobid/logo/ct$ct"."bic$bic"."m$motif".".fsa.meme";
	$check_dir = "$BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif"."/JASPAR/tomtom.html";
	if (!file_exists($check_dir)){
	header("Refresh: 1;url='prepare_tomtom.php?jobid=$jobid&ct=$ct&bic=$bic&m=$motif&db=$db'");
	#print_r ("start running");
	#mkdir ("$BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif");
	#mkdir ("$BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/HOCOMOCO");
	#mkdir ("$BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/JASPAR");
	#
	#$run_hoco = "nohup $BASE/program/meme/bin/tomtom  -no-ssc -oc $BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/HOCOMOCO -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 10.0 $motif_filename $BASE/program/motif_databases/HUMAN/HOCOMOCOv11_full_HUMAN_mono_meme_format.meme $BASE/program/motif_databases/MOUSE/HOCOMOCOv11_full_MOUSE_mono_meme_format.meme &";
	#$run_jas = "nohup $BASE/program/meme/bin/tomtom  -no-ssc -oc $BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/JASPAR -verbosity 1 -min-overlap 5 -mi 1 -dist pearson -evalue -thresh 10.0 $motif_filename $BASE/program/motif_databases/JASPAR/JASPAR2018_CORE_non-redundant.meme $BASE/program/motif_databases/JASPAR/JASPAR2018_CORE_vertebrates_non-redundant.meme &";
	#
	#system($run_hoco);
	#system($run_jas);
	
}   else if (file_exists("$BASE/data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/$db")){
	$status = "0";
	header("Location: data/$jobid/tomtom/ct$ct"."bic$bic"."m$motif/$db/tomtom.html");
}	else {

	header("Refresh: 30;url='prepare_tomtom.php?jobid=$jobid&ct=$ct&bic=$bic&m=$motif&db=$db'");
}
}

#print_r($check_dir);


$smarty->assign('filename',$filename);
$smarty->assign('jobid',$jobid);
$smarty->display('prepare_tomtom.tpl');

?>
