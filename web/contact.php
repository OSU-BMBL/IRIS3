<?php
require("config/smarty.php");
require("config/common.php");
require("config/tools.php");
        
$page = $_SERVER['PHP_SELF'];
$smarty->assign('page', $page);
   	$smarty->assign('theData', $theData);
	 $smarty->assign("download_flag", $download_flag);
	 $smarty->assign("download_url1", $download_url1);
	 $smarty->assign("download_url2", $download_url2);
        $smarty->display('contact.tpl');

?>
