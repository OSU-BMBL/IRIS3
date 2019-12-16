<?php
	require("config/common.php");
	require("config/smarty.php");
	$id = $_GET['id'];
	$jobid = $_GET['jobid'];
	$wd = "$BASE/data/$jobid/";
	system("cd $wd; nohup Rscript $BASE/program/plot_regulon.R $wd $id $jobid &");
	$response_array['status'] = 'success';  
	echo json_encode($response_array);
	#print_r($json);
	
?>
