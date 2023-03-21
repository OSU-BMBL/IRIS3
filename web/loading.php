<?php
set_time_limit(30000);
require_once("config/common.php");
require_once("config/smarty.php");
require_once("lib/spyc.php");
//error_reporting(E_ERROR | E_PARSE);
//require_once("lib/hmmer.php");
#$jobid=$_GET['jobid'];
$jobid = preg_replace("/\D+/", "", $_GET['jobid']);
$pvalue=$_GET['pvalue'];
if(empty($pvalue)) {
	$pvalue="0.05";
}

$integration_method_arg="";
$integration_input=array('');
$log1="";
$log2="";
$log="";
$status="";
$delete_flag="$DATAPATH/$jobid/delete.txt";
#$info = Spyc::YAMLLoad("$DATAPATH/$jobid/info.yaml");
$status= $info['status'];
$big=intval($info['big']);
$tempnam ="$DATAPATH/$jobid";	
$done_file = "$DATAPATH/$jobid/done";


$regulon_gene_symbol_file = array();
$regulon_file = array();
if (file_exists("$DATAPATH/$jobid/running_status.txt")){
	$running_status = `head -n1 "$DATAPATH/$jobid/running_status.txt"`;
	$running_status = preg_replace( "/\r|\n/", "", $running_status);
}

if (file_exists("$DATAPATH/$jobid/error_message.txt")){
	$error_message = `head -n20 "$DATAPATH/$jobid/error_message.txt"`;
	$error_message = preg_replace( "/\r|\n/", "", $error_message);
}

if (file_exists("$DATAPATH/$jobid/integration_input.txt")){
	$integration_input=array();
	$input_file = fopen("$DATAPATH/$jobid/integration_input.txt", "r");
	if ($input_file) {
		while (($line = fgets($input_file)) !== false) {
			array_push($integration_input,$line);
		}

		fclose($input_file);
	} else {
		//print_r("email file not found");
		// error opening the file.
	} 
}

if (file_exists("$DATAPATH/$jobid/info.txt")){
$param_file = fopen("$DATAPATH/$jobid/info.txt", "r");
	if ($param_file) {
		while (($line = fgets($param_file)) !== false) {
			$split_line = explode (",", $line);
			if($split_line[0] == "k_arg"){
				$k_arg = $split_line[1];
			} else if($split_line[0] == "f_arg"){
				$f_arg = $split_line[1];
			} else if($split_line[0] == "is_c"){
				if( strcmp($split_line[1], "-C") > 0) {
					$is_c = "Yes";
				} else{
					$is_c = "No";
				}
			} else if($split_line[0] == "is_imputation"){
				if( $split_line[1] == 1 || strcmp($split_line[1], "Yes") > 0) {
					$is_imputation = "Yes";
				} else{
					$is_imputation = "No";
				}
			} else if($split_line[0] == "remove_ribosome"){
				if( $split_line[1] == 1 || strcmp($split_line[1], "Yes") > 0) {
					$remove_ribosome = "Yes";
				} else{
					$remove_ribosome = "No";
				}
			}else if($split_line[0] == "promoter_arg"){
				$promoter_arg = $split_line[1];
			} else if($split_line[0] == "o_arg"){
				$o_arg = $split_line[1];
			} else if($split_line[0] == "motif_program"){
				if( $split_line[1] == 0) {
					$motif_program = "DMINDA";
				} else{
					$motif_program = "MEME";
				}
			} else if($split_line[0] == "label_use_predict"){
				if( $split_line[1] == 0 || $split_line[1] == 1) {
					$label_use_predict = "Seurat";
				} else{
					$label_use_predict = "user's label";
				}
			} else if($split_line[0] == "label_use_sc3"){
				if( $split_line[1] == 0 || $split_line[1] == 1) {
					$label_use_predict = "Seurat";
				} else{
					$label_use_predict = "user's label";
				}
			} else if($split_line[0] == "n_pca"){
				$n_pca = $split_line[1];
			} else if($split_line[0] == "n_variable_features"){
				$n_variable_features = $split_line[1];
			} else if($split_line[0] == "resolution_seurat"){
				$resolution_seurat = $split_line[1];
			} else if($split_line[0] == "expfile"){
				$expfile_name = $split_line[1];
			} else if($split_line[0] == "labelfile"){
				$labelfile_name = $split_line[1];
			} else if($split_line[0] == "gene_module_file"){
				$gene_module_file_name = $split_line[1];
			} else if($split_line[0] == "is_gene_filter"){
				if( $split_line[1] == 0) {
					$is_gene_filter = "No";
				} else{
					$is_gene_filter = "Yes";
				}
			} else if($split_line[0] == "is_cell_filter"){
				if( $split_line[1] == 0) {
					$is_cell_filter = "No";
				} else{
					$is_cell_filter = "Yes";
				}
			} else if($split_line[0] == "if_allowSave"){
				if( $split_line[1] == 0) {
					$if_allowSave = "No";
				} else{
					$if_allowSave = "Yes";
				}
			} else if($split_line[0] == "integration_method_arg"){
				$integration_method_arg = $split_line[1];
			} 
		}

		fclose($param_file);
	} else {
		//print_r("Info file not found");
		// error opening the file.
	} 
}

if(empty($remove_ribosome)){
	$remove_ribosome = "No";
}
if(empty($promoter_arg)){
	$promoter_arg = "1000";
}

if($expfile_name==="matrix.mtx"){
	$expfile_name = "Gene-barcode matrices (three gzip files)";
}

if (file_exists("$DATAPATH/$jobid/json/$jobid"."_umap.json")){
	$all_json = scandir("$DATAPATH/$jobid/json");
  $dge_json_file = preg_grep('/dge\.json/', $all_json);
	$count_dge = range(1,count($dge_json_file));
}


if (file_exists("$DATAPATH/$jobid/email.txt")){
$email_file = fopen("$DATAPATH/$jobid/email.txt", "r");
	if ($email_file) {
		while (($line = fgets($email_file)) !== false) {
			if($line == "flykun0620@gmail.com" ||strlen($line) == 0){
				$email_line = "Email not entered";
			} else {
				$email_line = $line;
			}
		}

		fclose($email_file);
	} else {
		//print_r("email file not found");
		// error opening the file.
	} 
}

if (file_exists("$DATAPATH/$jobid/species.txt")){
$species_file = fopen("$DATAPATH/$jobid/species.txt", "r");
	if ($species_file) {
		while (($line = fgets($species_file)) !== false) {
			$input_species = $line;
		}

		fclose($species_file);
	}
}

if (file_exists("$DATAPATH/$jobid/saving_plot1.jpeg")){
	$saving_plot1 = 1;
}

if (file_exists($done_file) && !file_exists($delete_flag) && file_exists("$DATAPATH/$jobid/$jobid"."_CT_1_bic.regulon_gene_symbol.txt")){
	if (file_exists("$DATAPATH/$jobid/$jobid"."_user_label_name.txt")){
		$lines = file("$DATAPATH/$jobid/$jobid"."_user_label_name.txt", FILE_IGNORE_NEW_LINES);
		$provided_cell_v = array_count_values($lines);
		
		#$provided_cell_value = array_flip($provided_cell_value);
		$provided_cell = array();
		
		foreach($provided_cell_v as $k => $v) {
			if($k==1){
				ksort($provided_cell_v);
			}
		}
		
		foreach($provided_cell_v as $k => $v) {
		 $provided_cell[] = $k;
		 $provided_cell_value[] = $v;
		}
		//print_r($provided_cell_v);
		
}else {
		//print_r("Info file not found");
		// error opening the file.
	}
	
if (file_exists("$DATAPATH/$jobid/$jobid"."_sc3_cluster_evaluation.txt")){
$evaluation_file = fopen("$DATAPATH/$jobid/$jobid"."_sc3_cluster_evaluation.txt", "r");
	if ($evaluation_file) {
		while (($line = fgets($evaluation_file)) !== false) {
			$split_line = explode (",", $line);
			if($split_line[0] == "ARI"){
				$ARI = $split_line[1];
			} else if($split_line[0] == "RI"){
				$RI = $split_line[1];
			} else if($split_line[0] == "JI"){
				$JI = $split_line[1];
			} else if($split_line[0] == "FMI"){
				$FMI = $split_line[1];
			} else if($split_line[0] == "Accuracy"){
				$Accuracy = $split_line[1];
			} else if($split_line[0] == "entropy"){
				$entropy = $split_line[1];
			} else if($split_line[0] == "purity"){
				$purity = $split_line[1];
			} 
		}
		fclose($evaluation_file);
	} 
}else {
		//print_r("Info file not found");
		// error opening the file.
	} 

if (file_exists("$DATAPATH/$jobid/$jobid"."_predict_cluster_evaluation.txt")){
$evaluation_file = fopen("$DATAPATH/$jobid/$jobid"."_predict_cluster_evaluation.txt", "r");
	if ($evaluation_file) {
		while (($line = fgets($evaluation_file)) !== false) {
			$split_line = explode (",", $line);
			if($split_line[0] == "ARI"){
				$ARI = $split_line[1];
			} else if($split_line[0] == "RI"){
				$RI = $split_line[1];
			} else if($split_line[0] == "JI"){
				$JI = $split_line[1];
			} else if($split_line[0] == "FMI"){
				$FMI = $split_line[1];
			} else if($split_line[0] == "Accuracy"){
				$Accuracy = $split_line[1];
			} else if($split_line[0] == "entropy"){
				$entropy = $split_line[1];
			} else if($split_line[0] == "purity"){
				$purity = $split_line[1];
			} 
		}
		fclose($evaluation_file);
	} 
}else {
		//print_r("Info file not found");
		// error opening the file.
	} 
	
$all_files = scandir("$DATAPATH/$jobid/");
$regulon_gene_symbol_file = preg_grep('/_CT_.+?_bic\.regulon_gene_symbol\.txt/', $all_files);
$regulon_id_file = preg_grep('/_CT_.+?_bic\.regulon_gene_id\.txt/', $all_files);
$regulon_motif_file = preg_grep('/_CT_.+?_bic\.regulon_motif\.txt/', $all_files);
$regulon_rank_file = preg_grep('/_CT_.+?_bic\.regulon_rank\.txt/', $all_files);
$motif_rank_file = preg_grep('/_CT_.+?_bic\.motif_rank\.txt/', $all_files);
$module_gene_name_file = preg_grep('/_module_.+?_bic\.regulon_gene_symbol\.txt/', $all_files);
$module_id_file = preg_grep('/_module_.+?_bic\.regulon_gene_id\.txt/', $all_files);
$module_motif_file = preg_grep('/_module_.+?_bic\.regulon_motif\.txt/', $all_files);

#print_r($regulon_gene_symbol_file);

/*
foreach (glob("$DATAPATH/$jobid/$jobid\_CT_*_bic.regulon_gene_symbol.txt") as $file) {
	$regulon_gene_symbol_file[] = $file;
  }
  
foreach (glob("$DATAPATH/$jobid/*regulon_gene_id.txt") as $file) {
  $regulon_id_file[] = $file;
}

foreach (glob("$DATAPATH/$jobid/*_bic.regulon_motif.txt") as $file) {
  $regulon_motif_file[] = $file;
}
foreach (glob("$DATAPATH/$jobid/*_bic.regulon_rank.txt") as $file) {
  $regulon_rank_file[] = $file;
}
foreach (glob("$DATAPATH/$jobid/*_bic.motif_rank.txt") as $file) {
  $motif_rank_file[] = $file;
}
*/

natsort($regulon_gene_symbol_file);
natsort($regulon_id_file);
natsort($regulon_motif_file);
natsort($regulon_rank_file);
natsort($motif_rank_file);
$regulon_gene_symbol_file = array_values($regulon_gene_symbol_file);
$regulon_id_file = array_values($regulon_id_file);
$regulon_motif_file = array_values($regulon_motif_file);
$regulon_rank_file = array_values($regulon_rank_file);
$motif_rank_file = array_values($motif_rank_file);

$count_ct = range(1,count($regulon_gene_symbol_file));
/*
foreach (glob("$DATAPATH/$jobid/$jobid\_module_*_bic.regulon_gene_symbol.txt") as $file) {
  $module_gene_name_file[] = $file;
}
foreach (glob("$DATAPATH/$jobid/$jobid\_module_*regulon_gene_id.txt") as $file) {
  $module_id_file[] = $file;
}

foreach (glob("$DATAPATH/$jobid/$jobid\_module_*_bic.regulon_motif.txt") as $file) {
  $module_motif_file[] = $file;
}

*/
if(sizeof($module_gene_name_file)){
	natsort($module_gene_name_file);
	natsort($module_id_file);
	natsort($module_motif_file);
	$module_gene_name_file = array_values($module_gene_name_file);
	$module_id_file = array_values($module_id_file);
	$module_motif_file = array_values($module_motif_file);
	$count_module = range(1,count($module_gene_name_file));
}


$info_file = fopen("$DATAPATH/$jobid/$jobid"."_info.txt", "r");
$count_regulon_in_ct = array(); 
$count_ctsr_in_ct = array(); 
if ($info_file) {
    while (($line = fgets($info_file)) !== false) {
        $split_line = explode (",", $line);
		if($split_line[0] == "filter_gene_num"){
			$filter_gene_num = $split_line[1];
		} else if($split_line[0] == "filter_cell_num"){
			$filter_cell_num = $split_line[1];
		} else if($split_line[0] == "total_gene_num"){
			$total_gene_num = $split_line[1];
		}  else if($split_line[0] == "total_cell_num"){
			$total_cell_num = $split_line[1];
		} else if($split_line[0] == "filter_gene_rate"){
			$filter_gene_rate = $split_line[1];
		} else if($split_line[0] == "filter_cell_rate"){
			$filter_cell_rate = $split_line[1];
		} else if($split_line[0] == "total_label"){
			$total_label = $split_line[1];
		} else if($split_line[0] == "total_bic"){
			$total_bic = $split_line[1];
		} else if($split_line[0] == "total_ct"){
			$total_ct = $split_line[1];
		} else if($split_line[0] == "total_regulon"){
			$total_regulon = $split_line[1];
		} else if($split_line[0] == "is_evaluation"){
			$is_evaluation = $split_line[1];
		} else if($split_line[0] == "species"){
			$species = $split_line[1];
		} else if($split_line[0] == "main_species"){
			$main_species = $split_line[1];
		} else if($split_line[0] == "second_species"){
			$second_species = $split_line[1];
		} else if($split_line[0] == "provide_label"){
			$provide_label = $split_line[1];
		} else if($split_line[0] == "predict_label"){
			$predict_label = $split_line[1];
		}
    }
	
	if ($species == $main_species) {
		$main_species = "";
	}
    fclose($info_file);
} else {
	print_r("Info file not found");
    // error opening the file.
} 

if(empty($total_cell_num)) {
	$total_cell_num = 5000;
}

$predict_label_array = array();
if (file_exists("$DATAPATH/$jobid/$jobid"."_sc3_label.txt") && !file_exists("$DATAPATH/$jobid/$jobid"."_predict_label.txt")){
	$predict_label_file = fopen("$DATAPATH/$jobid/$jobid"."_sc3_label.txt", "r");

	while (($line = fgets($predict_label_file)) !== false) {
	$split_line = explode ("\t", $line);
	array_push($predict_label_array,$split_line[1]);
	}
	array_shift($predict_label_array);
	$predict_label_array = array_count_values($predict_label_array);
	$predict_label_array = array_values($predict_label_array);

	fclose($predict_label_file);
	} else {
	//print_r("Silh file not found");
}

if (file_exists("$DATAPATH/$jobid/$jobid"."_predict_label.txt")){
	$predict_label_file = fopen("$DATAPATH/$jobid/$jobid"."_predict_label.txt", "r");

	while (($line = fgets($predict_label_file)) !== false) {
	$split_line = explode ("\t", $line);
	array_push($predict_label_array,$split_line[1]);
	}
	array_shift($predict_label_array);
	$predict_label_array = array_count_values($predict_label_array);
	$predict_label_array = array_values($predict_label_array);

	fclose($predict_label_file);
	} else {
	//print_r("Silh file not found");
}

if (file_exists("$DATAPATH/$jobid/$jobid"."_silh.txt")){
$silh_file = fopen("$DATAPATH/$jobid/$jobid"."_silh.txt", "r");
if ($silh_file) {
	$silh_trace = $silh_x = $silh_y  = $line_cell = $line_result = array(); 
	
	for ($i=1;$i <= $predict_label;$i++){
		$silh_file = fopen("$DATAPATH/$jobid/$jobid"."_silh.txt", "r");
		$line_cell = $line_result = array(); 
		while (($line = fgets($silh_file)) !== false) {
        $split_line = explode (",", $line);
		$split_line[2] = preg_replace( "/\r|\n/", "", $split_line[2] );
			if($i == (int)$split_line[0]){
				
				array_push($line_cell, $split_line[1]);
				array_push($line_result, $split_line[2]);
			}
		}
		$silh_x[$i] = $line_cell;
		$silh_y[$i] = $line_result;
		array_push($silh_trace,$i);
	}
    fclose($silh_file);
	#$silh_trace = json_encode($silh_trace);
	#$silh_x = json_encode($silh_x);
	#$silh_y = json_encode($silh_y);
} else {
	print_r("Info file not found");
    // error opening the file.
} 
} else {
	//print_r("Silh file not found");
}
if (file_exists("$DATAPATH/$jobid/$jobid"."_sankey.txt")){
	$sankey_file = fopen("$DATAPATH/$jobid/$jobid"."_sankey.txt", "r");
	if ($sankey_file) {
	$sankey_nodes = $sankey_src = $sankey_target = $sankey_value =$sankey_label_order = array(); 
    while (($line = fgets($sankey_file)) !== false) {
        $split_line = explode (",", $line);
		$split_line[1] = preg_replace( "/\r|\n/", "", $split_line[1] );
		if($split_line[0] == "src"){
			array_push($sankey_src,$split_line[1]);
		} else if($split_line[0] == "target"){
			array_push($sankey_target,$split_line[1]);
		} else if($split_line[0] == "value"){
			array_push($sankey_value,$split_line[1]);
		} else if($split_line[0] == "nodes"){
			array_push($sankey_nodes,$split_line[1]);
		} else if($split_line[0] == "label_order"){
			array_push($sankey_label_order,$split_line[1]);
		}
    }
    fclose($sankey_file);
	$sankey_src = json_encode($sankey_src);
	$sankey_target = json_encode($sankey_target);
	$sankey_value = json_encode($sankey_value);
	$sankey_nodes_count = count($sankey_nodes) - count($silh_trace);
	$sankey_nodes = json_encode($sankey_nodes);
	#$sankey_label_order = json_encode($sankey_label_order);
} else {
	print_r("Info file not found");
    // error opening the file.
} 
}

foreach ($regulon_gene_symbol_file as $key=>$this_regulon_gene_symbol_file){
	
	$status = "1";
	$fp = fopen("$DATAPATH/$jobid/$this_regulon_gene_symbol_file", 'r');
	if ($fp){
	while (($line = fgetcsv($fp, 0, "\t")) !== FALSE) if ($line) {
		$regulon_result[$key][] = array_map('trim',$line);
	}
	//$count_regulon_in_ct[$key] = count($regulon_result[$key])
	
	array_push($count_regulon_in_ct,count($regulon_result[$key]));
	} else{
		die("Unable to open file");
	}
	if(!filesize("$DATAPATH/$jobid/$this_regulon_gene_symbol_file")) {
	$regulon_result[$key][0] = '0';
	}
	fclose($fp);
	}
foreach ($regulon_id_file as $key=>$this_regulon_id_file){
	
	$status = "1";

	$fp = fopen("$DATAPATH/$jobid/$this_regulon_id_file", 'r');
	if ($fp){
	while (($line = fgetcsv($fp, 0, "\t")) !== FALSE) 
		if ($line) {$regulon_id_result[$key][] = array_map('trim',$line);}
	} else{
		die("Unable to open file");
	}
	fclose($fp);
	}
	
foreach ($regulon_motif_file as $key=>$this_regulon_motif_file){
	$status = "1";
	$fp = fopen("$DATAPATH/$jobid/$this_regulon_motif_file", 'r');
	if ($fp){
	while (($line = fgetcsv($fp, 0, "\t")) !== FALSE) 
		if ($line) {
			$tmp =array_map('trim',$line);
			if (count($tmp) > 2) {
				$tmp = array_slice($tmp, 0, 2, true);
			}
			$regulon_motif_result[$key][] = $tmp;
			}
	} else{
		die("Unable to open file");
	}
	fclose($fp);
	}
	
foreach ($regulon_rank_file as $key=>$this_regulon_rank_file){
	$status = "1";
	$this_ctsr = 0;
	$fp = fopen("$DATAPATH/$jobid/$this_regulon_rank_file", 'r');
	if ($fp){
	while (($line = fgetcsv($fp, 0, "\t")) !== FALSE) 
		if ($line) {
			$regulon_rank_result[$key][] = array_map('trim',$line);
			if($line[4] < floatval($pvalue)) {
				$this_ctsr = $this_ctsr + 1;
			}
		}
		array_push($count_ctsr_in_ct,$this_ctsr);
	} else{
		die("Unable to open file");
	}
	fclose($fp);
	}
	
foreach ($motif_rank_file as $key=>$this_motif_rank_file){
	$status = "1";
	$fp = fopen("$DATAPATH/$jobid/$this_motif_rank_file", 'r');
	if ($fp){
	while (($line = fgetcsv($fp, 0, "\t")) !== FALSE) 
		if ($line) {$motif_rank_result[$key][] = array_map('trim',$line);}
	} else{
		die("Unable to open file");
	}
	fclose($fp);
}

function getStringBetween($str,$from,$to)
{
    $sub = substr($str, strpos($str,$from)+strlen($from),strlen($str));
    return substr($sub,0,strpos($sub,$to));
}

if (file_exists("$DATAPATH/$jobid/$jobid"."_tomtom_result.txt")){
	$tomtom_result_file = fopen("$DATAPATH/$jobid/$jobid"."_tomtom_result.txt", "r");
	if ($tomtom_result_file) {
		while (($line = fgets($tomtom_result_file)) !== false) {
			$split_line = explode ("\t", $line);
			$motif_name = $split_line[0];
			$tomtom_result[$motif_name][] = array_map('trim',$split_line);
		}
		fclose($tomtom_result_file);
	} 
}

if(sizeof($module_gene_name_file)){
	foreach ($module_gene_name_file as $key=>$this_module_gene_name_file){
	$fp = fopen("$DATAPATH/$jobid/$this_module_gene_name_file", 'r');
	 if ($fp){
	 while (($line = fgetcsv($fp, 0, "\t")) !== FALSE) if ($line) {
		 $module_result[$key][] = array_map('trim',$line);
		 
	 }
	 } else{
		 die("Unable to open file");
	 }
	fclose($fp);
	}
	
	foreach ($module_id_file as $key=>$this_module_id_file){
	$fp = fopen("$DATAPATH/$jobid/$this_module_id_file", 'r');
	if ($fp){
	while (($line = fgetcsv($fp, 0, "\t")) !== FALSE) 
		if ($line) {$module_id_result[$key][] = array_map('trim',$line);}
	} else{
		die("Unable to open file");
	}
	fclose($fp);
	}

	foreach ($module_motif_file as $key=>$this_module_motif_file){
	
	$fp = fopen("$DATAPATH/$jobid/$this_module_motif_file", 'r');
	if ($fp){
	while (($line = fgetcsv($fp, 0, "\t")) !== FALSE) 
		if ($line){
			$module_motif_result[$key][] = array_map('trim',$line);
			
			}
	} else{
		die("Unable to open file");
	}
	fclose($fp);
	}
}

function exception_handler($exception) {
  echo '<div class="alert alert-danger">';
  echo '<b>Fatal error</b>:  Uncaught exception \'' . get_class($exception) . '\' with message ';
  echo $exception->getMessage() . '<br>';
  echo 'Stack trace:<pre>' . $exception->getTraceAsString() . '</pre>';
  echo 'thrown in <b>' . $exception->getFile() . '</b> on line <b>' . $exception->getLine() . '</b><br>';
  echo '</div>';
}

set_exception_handler('exception_handler');
} else if (file_exists("$DATAPATH/$jobid/error_message.txt")) {
	$status= "other";
} else if (file_exists($done_file) && !file_exists($delete_flag) && file_exists("$DATAPATH/$jobid/$jobid"."_CT_1_regulon_gene_id.txt") && !file_exists("$DATAPATH/$jobid/$jobid"."_CT_1_bic/bic1.txt.fa.closures")) {
	$status= "error_bic";
}else if (file_exists($done_file) && !file_exists($delete_flag) && !file_exists("$DATAPATH/$jobid/$jobid"."_cell_label.txt")) {
	$status= "error_num_cells";
}else if (file_exists($done_file) && !file_exists($delete_flag) && !file_exists("$DATAPATH/$jobid/$jobid"."_CT_1_regulon_gene_id.txt")) {
	$status= "error";
}else if (!file_exists($tempnam) || file_exists($delete_flag)) {
	$status= "404";
}else {
	$status = "0";
	header("Refresh: 60;url='results.php?jobid=$jobid'");
}

$smarty->assign('integration_input', $integration_input);
$smarty->assign('running_status',$running_status);
$smarty->assign('filter_gene_num',$filter_gene_num);
$smarty->assign('total_gene_num',$total_gene_num);
$smarty->assign('filter_gene_rate',$filter_gene_rate);
$smarty->assign('filter_cell_num',$filter_cell_num);
$smarty->assign('total_cell_num',$total_cell_num);
$smarty->assign('filter_cell_rate',$filter_cell_rate);
$smarty->assign('total_label',$total_label);
$smarty->assign('total_bic',$total_bic);
$smarty->assign('total_ct',$total_ct);
$smarty->assign('total_regulon',$total_regulon);
$smarty->assign('count_ct',$count_ct);
$smarty->assign('count_dge',$count_dge);
$smarty->assign('species',$species);
$smarty->assign('second_species',$second_species);
$smarty->assign('main_species',$main_species);
$smarty->assign('input_species',$input_species);
$smarty->assign('status',$status);
$smarty->assign('jobid',$jobid);
$smarty->assign('pvalue',$pvalue);
$smarty->assign('count_regulon_in_ct',$count_regulon_in_ct);
$smarty->assign('count_ctsr_in_ct',$count_ctsr_in_ct);
$smarty->assign('regulon_result',$regulon_result);
$smarty->assign('regulon_id_result',$regulon_id_result);
$smarty->assign('regulon_motif_result',$regulon_motif_result);
$smarty->assign('regulon_rank_result',$regulon_rank_result);
$smarty->assign('motif_rank_result',$motif_rank_result);
$smarty->assign('tomtom_result',$tomtom_result);
$smarty->assign('module_result',$module_result);
$smarty->assign('module_id_result',$module_id_result);
$smarty->assign('module_motif_result',$module_motif_result);
$smarty->assign('big',$big);
$smarty->assign('predict_label',$predict_label);
$smarty->assign('provide_label',$provide_label);
$smarty->assign('f_arg',$f_arg);
$smarty->assign('k_arg',$k_arg);
$smarty->assign('o_arg',$o_arg);
$smarty->assign('is_c',$is_c);
$smarty->assign('is_imputation',$is_imputation);
$smarty->assign('remove_ribosome',$remove_ribosome);
$smarty->assign('promoter_arg',$promoter_arg);
$smarty->assign('ARI',$ARI);
$smarty->assign('RI',$RI);
$smarty->assign('JI',$JI);
$smarty->assign('FMI',$FMI);
$smarty->assign('email_line',$email_line);
$smarty->assign('saving_plot1',$saving_plot1);
$smarty->assign('Accuracy',$Accuracy);
$smarty->assign('entropy',$entropy);
$smarty->assign('count_ct',$count_ct);
$smarty->assign('count_module',$count_module);
$smarty->assign('provided_cell',$provided_cell);
$smarty->assign('provided_cell_value',$provided_cell_value);
$smarty->assign('purity',$purity);
$smarty->assign('motif_program',$motif_program);
$smarty->assign('label_use_predict',$label_use_predict);
$smarty->assign('n_variable_features',$n_variable_features);
$smarty->assign('integration_method_arg',$integration_method_arg);
$smarty->assign('n_pca',$n_pca);
$smarty->assign('resolution_seurat',$resolution_seurat);
$smarty->assign('expfile_name',$expfile_name);
$smarty->assign('labelfile_name',$labelfile_name);
$smarty->assign('gene_module_file_name',$gene_module_file_name);
$smarty->assign('is_gene_filter',$is_gene_filter);
$smarty->assign('is_cell_filter',$is_cell_filter);
$smarty->assign('if_allowSave',$if_allowSave);
$smarty->assign('LINKPATH', $LINKPATH);
$smarty->assign('silh_trace',$silh_trace);
$smarty->assign('silh_y',$silh_y);
$smarty->assign('silh_x',$silh_x);
$smarty->assign('error_message',$error_message);
$smarty->assign('sankey_src',$sankey_src);
$smarty->assign('sankey_target',$sankey_target);
$smarty->assign('sankey_value', $sankey_value);
$smarty->assign('sankey_nodes', $sankey_nodes);
$smarty->assign('sankey_label_order', $sankey_label_order);
$smarty->assign('sankey_nodes_count', $sankey_nodes_count);
$smarty->assign('predict_label_array', $predict_label_array);

$smarty->setCacheLifetime(3600000);
$smarty->display('loading.tpl');

?>
