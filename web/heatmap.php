<?php
require_once("config/common.php");
require_once("config/smarty.php");
require_once("lib/spyc.php");
//require_once("lib/hmmer.php");
$jobid=$_GET['jobid'];
$filename=$_GET['file'];
//$encodedString = json_encode($annotation1);
 
//Save the JSON string to a text file.
//file_put_contents('json_array.txt', $encodedString);
$smarty->assign('filename',$filename);
$smarty->assign('jobid',$jobid);
$smarty->display('heatmap.tpl');

?>
