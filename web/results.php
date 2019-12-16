<?php
require("config/smarty.php");
require("config/common.php");
require("config/tools.php");
        
$page = $_SERVER['PHP_SELF'];
$jobid=$_GET['jobid'];
if (file_exists("$DATAPATH/$jobid/$jobid"."_info.txt")){
    $info_file = fopen("$DATAPATH/$jobid/$jobid"."_info.txt", "r");
    $count_regulon_in_ct = array(); 
    if ($info_file) {
        while (($line = fgets($info_file)) !== false) {
            $split_line = explode (",", $line);
            if($split_line[0] == "total_regulon"){
                $total_regulon = $split_line[1];
            } 
        }
        fclose($info_file);
    } else {
        print_r("Info file not found");
        // error opening the file.
    } 
}
$total_regulon = $total_regulon / 18;
$wait_time = (round($total_regulon)%5 === 0) ? round($total_regulon) : round(($total_regulon+2.5)/5)*5;
if ($wait_time == "") {
    $wait_time = "10-20";
}

$smarty->assign('page', $page);
$smarty->assign('wait_time',$wait_time);
$smarty->display('results.tpl');
?>
