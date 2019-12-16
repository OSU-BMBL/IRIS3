<?php
	require("config/common.php");
	require("config/smarty.php");
	$jobid = $_GET['jobid'];
	$regulon_id=$_GET['regulon_id'];
	$species=$_GET['species'];
	$table_content_id=$_GET['table'];
	$wd = "./data/$jobid/";
	system("cd $wd; $BASE/program/count_peak_overlap_single_file.sh $wd $regulon_id $species");
	#echo "<table id='$table_content_id' border='1'>
	#<tr>
	#<th>$jobid</th>
	#<th>$regulon_id</th>
	#<th>$species </th>
	#</tr></table>";
	#
	#$db_contents=file_get_contents($db_file);
	$db_file= "$wd/atac/$regulon_id.atac_overlap_result.txt";
	$fp = fopen("$db_file", 'r');
	if ($fp){
	while (($line = fgetcsv($fp, 0, "\t")) !== FALSE){
		if ($line) {
			$test_json['data'][] = array_map('trim',$line);
			#print_r($count);
		}
	}
	} else{
		die("Unable to open file");
	}
	fclose($fp);
	echo json_encode($test_json); 
	#print_r($json);
	
?>
