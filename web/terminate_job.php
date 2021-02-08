<?php
	require("config/common.php");
	require("config/smarty.php");
	$jobid = $_GET['jobid'];
	$regulon_id=$_GET['regulon_id'];
	$species=$_GET['species'];
	$wd = "$BASE/data/$jobid";
	if (substr($jobid, 0, 3) === "202") {
		system("cd $wd; rm *");
		system("cd $wd; echo rm -R $jobid >> delete.txt");
		
	}
	
	#echo "<table id='$table_content_id' border='1'>
	#<tr>
	#<th>$jobid</th>
	#<th>$regulon_id</th>
	#<th>$species </th>
	#</tr></table>";
	#
	#$db_contents=file_get_contents($db_file);
	#print_r($json);
	
?>
