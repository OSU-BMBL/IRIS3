<?php
require("config/smarty.php");
require("config/common.php");
require("config/tools.php");

$page = $_SERVER['PHP_SELF'];
$smarty->assign('page', $page);
$smarty->display('news.tpl');

?>
