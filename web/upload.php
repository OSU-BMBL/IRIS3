<?php
require ("config/smarty.php");
require ("config/common.php");
require ("config/tools.php");
function detectDelimiter($csvFile) {
    $delimiters = array(';' => 0, ',' => 0, "\t" => 0, "|" => 0, " " => 0,);
    $handle = fopen($csvFile, "r");
    $firstLine = fgets($handle);
    fclose($handle);
    foreach ($delimiters as $delimiter => & $count) {
        $count = count(str_getcsv($firstLine, $delimiter));
    }
    return array_search(max($delimiters), $delimiters);
}
$json = $_POST['filename'];
if (!empty($_FILES)) {
    session_start();
    $jobid = $_SESSION['jobid'];
    if ($jobid == "") {
        $jobid = date("YmdGis");
    } else {
    }
    $_SESSION['jobid'] = $jobid;
    $workdir = "./data/$jobid/";
    if (!file_exists($workdir)) {
        mkdir($workdir);
    }
    #check php.ini reach maximum upload size
    $temp_file = $_FILES['file']['tmp_name'];
    $csv = file_get_contents($temp_file);
    $delim = detectDelimiter($temp_file);
    $array = file($temp_file);
	$file_info = new finfo(FILEINFO_MIME); // object oriented approach!
	$mime_type = $file_info->buffer(file_get_contents($temp_file));  // e.g. gives "image/jpeg"
	$mime_type = explode(";",$mime_type)[0];
	#echo($mime_type);
	switch($mime_type) {
	case "application/x-gzip":
		$new_array['type'][] = 'gzip';
		$fp = fopen("$workdir/upload_type.txt", 'w');
		fwrite($fp,"TenX.folder\n");
		fclose($fp);
		break;
	case "application/zip":
		$new_array['type'][] = 'zip';
		$fp = fopen("$workdir/upload_type.txt", 'w');
		fwrite($fp,"TenX.folder\n");
		fclose($fp);
		break;
	case "text/plain":
		#$new_array = array();
		#foreach ($array as $line) {
		#    // explode the line on tab. Note double quotes around \t are mandatory
		#    $line_array = explode("$delim", $line);
		#    // set first element to the new array
		#    #$new_array[] = $line_array[0];
		#	$new_array[] = array_map('trim',$line_array);
		#}
		$fp = fopen("$temp_file", 'r');
		if ($fp) {
			$idx = 0;
			$count_zero = 0;
			while (($line = fgetcsv($fp, 0, "$delim")) !== FALSE) {
				if ($line) {
					if ($idx == 0) {
						$remove_first = array_shift($line);
						$new_array['columns'][] = $line;
					} else {
						$new_array['index'][] = array_map('trim', $line) [0];
						$remove_first = array_shift($line);
						$new_array['data'][] = array_map('trim', $line);
						$count_zero = $count_zero + count(array_filter($line));
					}
				}
				$idx = $idx + 1;
				if ($idx == 10) {
					break;
				}
				/*if ($new_array['columns'][0] > 1000) {
				
				}*/
			}
		} else {
			die("Unable to open file");
		} 
		fclose($fp);
		$fp = fopen("$temp_file", 'r');
		if ($fp) {
			$linecount = - 2;
			while (!feof($fp)) {
				$line = fgets($fp);
				$linecount++;
			}
		}
		$new_array['gene_num'][] = $linecount;
		$new_array['count_zero'][] = $count_zero;
		$new_array['type'][] = 'text';
		fclose($fp);
		$fp = fopen("$workdir/upload_type.txt", 'w');
		fwrite($fp,"CellGene\n");
		fclose($fp);
		break;
	case "application/x-hdf":
		$new_array['index'][] = '1';
		$new_array['data'][] = '1';
		$new_array['gene_num'][] = 100;
		$new_array['count_zero'][] = 50;
		$new_array['type'][] = 'hdf';
		$fp = fopen("$workdir/upload_type.txt", 'w');
		fwrite($fp,"TenX.h5\n");
		fclose($fp);
		break;
	case "text/plainss":
		$new_array['type'][] = 'other';
		break;
	}

    #$response = json_encode($array);
    $filetype = $_POST['filetype'];
    $_SESSION['filetype'] = $filetype;
    if ($filetype == "dropzone_exp") {
        $expfile = $_FILES['file']['name'];
        $expfile = str_replace(" ", "_", $expfile);
        $expfile = str_replace(array('(', ')'), '_', $expfile);
        $_SESSION['expfile'] = $expfile;
        $location = $workdir . $expfile;
        move_uploaded_file($temp_file, $location);
    } else if ($filetype == "dropzone_label") {
        $labelfile = $_FILES['file']['name'];
        $labelfile = str_replace(" ", "_", $labelfile);
        $labelfile = str_replace(array('(', ')'), '_', $labelfile);
        $location = $workdir . $labelfile;
        $_SESSION['labelfile'] = $labelfile;
        move_uploaded_file($temp_file, $location);
    } else if ($filetype == "dropzone_gene_module") {
        $gene_module_file = $_FILES['file']['name'];
        $gene_module_file = str_replace(" ", "_", $gene_module_file);
        $gene_module_file = str_replace(array('(', ')'), '_', $gene_module_file);
        $location = $workdir . $gene_module_file;
        $_SESSION['gene_module_file'] = $gene_module_file;
        move_uploaded_file($temp_file, $location);
    } else {
        $_SESSION['expfile'] = "test";
    }
    #$response=$new_array;
    $new_array['data'] = array_slice($new_array['data'], 0, 10);
    $new_array['index'] = array_slice($new_array['index'], 0, 10);
    echo json_encode($new_array);
} else if ($_POST['filename'] == "clear") {
    session_start();
    $jobid = $_SESSION['jobid'];
    if ($jobid == "") {
        $jobid = date("YmdGis");
    } else {
    }
    $_SESSION['jobid'] = $jobid;

    #system("cp ./upload/CeRIS_example_gene_module.csv $workdir");
    $expfile = '';
    $_SESSION['expfile'] = $expfile;
    $labelfile = '';
    $_SESSION['labelfile'] = $labelfile;
    $gene_module_file = '';
    $_SESSION['gene_module_file'] = $gene_module_file;
    
}else if ($json != "") {
    $example = $_POST['filename'];
    session_start();
    $jobid = $_SESSION['jobid'];
    if ($jobid == "") {
        $jobid = date("YmdGis");
    } else {
    }
    $_SESSION['jobid'] = $jobid;
    $workdir = "./data/$jobid/";
    if (!file_exists($workdir)) {
        mkdir($workdir);
    }
    system("cp ./upload/Yan_2013_expression.csv $workdir");
    system("cp ./upload/Yan_2013_label.csv $workdir");
    #system("cp ./upload/CeRIS_example_gene_module.csv $workdir");
    $expfile = 'Yan_2013_expression.csv';
    $_SESSION['expfile'] = $expfile;
    $labelfile = 'Yan_2013_label.csv';
    $_SESSION['labelfile'] = $labelfile;
    #$gene_module_file = 'Yan_2013_example_gene_module.csv';
    #$_SESSION['gene_module_file'] = $gene_module_file;
    
}
$page = $_SERVER['PHP_SELF'];
$smarty->assign('jobid', $jobid);
$smarty->assign('expfile', $expfile);
$smarty->assign('labelfile', $labelfile);
$smarty->assign('page', $page);
$smarty->assign('res', $response);
die();
?>
