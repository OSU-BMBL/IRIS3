<?php
require_once("config/common.php");
require_once("config/smarty.php");
require_once("lib/spyc.php");
//require_once("lib/hmmer.php");
$jobid=$_GET['jobid'];
$ct=$_GET['ct'];
$module=$_GET['module'];
$bic=$_GET['bic'];
$id=$_GET['id'];
$from=$_GET['from'];
$max=0;
$DATAPATH="$BASE/data";
$TOOLPATH="$BASE/program/dminda";
session_start();

$motif_tmp_filename="ct".$ct."bic".$bic."m".$id;
$ct_path=$DATAPATH."/".$jobid."/".$jobid."_CT_".$ct."_bic/";
$motif_background_filename=$ct_path."bic".$bic.".txt.fa";
$tempnam =$ct_path."bic".$bic.".txt.fa.closures";
print_r($module);
if ($module != "") {
	$motif_tmp_filename="module".$module."bic".$bic."m".$id;
	$ct_path=$DATAPATH."/".$jobid."/".$jobid."_module_".$module."_bic/";
	$motif_background_filename=$ct_path."bic".$bic.".txt.fa";
	$tempnam =$ct_path."bic".$bic.".txt.fa.closures";
}

if(file_exists($tempnam)&& file_get_contents($tempnam)!="")
{  

 /*  $key=0;
   $lengthseq=array();
   $fk = fopen("$DATAPATH/$jobid/$jobid"."tg", 'r');
	   while(!feof($fk)) 
	  	   {
	  	  $line=fgets($fk);
	      if(preg_match("/^>/",$line))
	      {$key++;
	      	
	      }
	      else
	      {
	      	$as=strlen($line);
	      		array_push($lengthseq,$as);
	      }
	  	   }
	  fclose($fk);  */
	  $i=0;
	    $num=0;
	    $result=array();
	    $array=array();   
		$motif_count=0;
	          $fp = fopen($tempnam, 'r');
	             while(!feof($fp)) {
		                   $line=fgets($fp);
						   
                           /*if(preg_match("/^\*{57}/",$line))
		                       	{   $line1=fgets($fp);
									
		                       		if(strlen($line1)!=1)
		                       		    {
                                     	$arr=explode(" ",chop($line1));
										
                                    if($arr[5]!="")
									{ 
									
									
									array_push($result,$arr[5]);
										
									}
                                  }
		                       	
		                       	} */
		                     if(preg_match("/Consensus/",$line))
		                       	{    $line1=fgets($fp);
							
							$motif_count = $motif_count + 1;
									array_push($result,$line1);
		                       		
		                       	} 
		                       	if(strpos($line,"Motif length:"))
		                       	{$arr=explode(" ",$line);
		                       
		                       	array_push($result,$arr[3]);
		                       	}
		                       	if(strpos($line,"Motif number:"))
		                       	{$arr=explode(" ",$line);
		                       			$num=(int)$arr[3];
		                    
		                       	array_push($result,$arr[3]);
		                       	}
								
		                       	if(strpos($line,"Motif Pvalue:"))
		                       	{$arr=explode(" ",$line);
		                       	array_push($result,$arr[3]);
		                       	}
		                       
		                       	if(strpos($line,"Aligned Motif"))
		                       	{$line=fgets($fp);
		                       	while($num!=-5)
		                       	{$key1=0;
		                       		$line=fgets($fp);
									
								
		                       //echo $i."!$num!$line<br>";
		                       // echo "$key==$key1,$num,$line,<br>";
		                        if(strpos($line,"the best")&&strpos($line,"convinced"))
		                        {	$arr=explode(" ",$line);
									
		                        	$key1=(int)$arr[2];
		                       		array_push($result,$arr[2]);
									array_push($result,$arr[11]);
		                       		}
		                       else if((!strpos($line,"the best"))&&strpos($line,"convinced"))
		                       {$arr=explode(" ",$line);
								
		                       	array_push($result,$arr[2]);
		                       	array_push($result,$arr[9]);
		                       	}
		                       	 else if(strpos($line,"the best")&&(!strpos($line,"convinced"))&&$num==-1)
		                       {$arr=explode(" ",$line);
								
		                       	array_push($result,$arr[2]);
		                       	array_push($result,$arr[10]);
		                       	}
		
		                       else if(strpos($line,'>')===0)
		                       { 
								
		                       	$arr=explode("\t",$line);
		                       	array_push($array,$arr[1]);
		                       	array_push($array,$arr[2]);
		                       	array_push($array,$arr[3]); #order
		                       	array_push($array,$arr[4]);
		                       	array_push($array,$arr[5]);
		                        array_push($array,$arr[6]);
		                      }
		                       	$num=$num-1;
		                       	}
		                       	
		                       	$num=0;
		                       	}
	                     }
	
	          fclose($fp);
    
	     $n=0;$m=0;$i=0;
	     $annotation1=array();
	     $motifs=array();
	  $scr="#!/usr/bin/env sh\ncd $TOOLPATH/weblogo-3.3\n";
	   $total_idx = 0;
	for($k=0;$k<$motif_count;$k++)
	{	
			
			$n = 0;
			while($n < $result[$k*4+1]){
				
			$motifs[$n]=array(
						'red'=>1,
						'Seq'=>$array[6*($n+$total_idx)],
						'start'=>$array[6*($n+$total_idx)+1],
						'end'=>$array[6*($n+$total_idx)+2],
						'Motif'=>$array[6*($n+$total_idx)+3],
						'Score'=>$array[6*($n+$total_idx)+4],
						'Info'=>$array[6*($n+$total_idx)+5],
            //'seqlen'=>$lengthseq[($array[$n]-1)],
            );
			
			$n = $n + 1;
			}
		$total_idx = $total_idx + $result[$k*4+1];
	     
	// fclose($fp);

//$scr=$scr."./weblogo --format PNG --color black A 'PurineA' --color green G 'PurineG' --color red T 'PyrimidineT' --color blue C 'PyrimidineC' < ".$tempnam."-motifin".($i+1)." > ".$tempnam."-motifin".($i+1).".png\n";
	 	$annotation1[$k]=array(
	 	    'Motifname'=>$motif_tmp_filename,
	 			'Motifid'=>$k+1,
	 			'Consensus'=>$result[$k*4+3],
	 			'Motiflength'=>$result[$k*4],
	 			'Motifnumber'=>$result[$k*4+1],
	 			'MotifPvalue'=>$result[$k*4+2],
	 			'firstn'=>$result[$k],
	 			'firstp'=>$result[$k],
	 			'Motifs'=>$motifs
	 	        );
			unset($motifs);
			 #print_r($annotation1[0]['Motifs']);
			 
			$i++;
	}
	
	
   /*  $fp = fopen("$DATAPATH/$jobid/weblogo.sh", 'w');
     fwrite($fp, $scr);
     fclose($fp);
	   if($status=="done")
     {    
       system("nohup sh $DATAPATH/$jobid/weblogo.sh >wlog &");
       $status="Run";
        	$info['status']= $status;
          $fp = fopen("$DATAPATH/$jobid/info.yaml", 'w');
          fwrite($fp, Spyc::YAMLDump($info));
          fclose($fp);
      
     } 
	      if(file_exists($tempnam.$annotation1[count($annotation1)-1]['Motifname'].".png") )
         { $status="Done";
        	$info['status']= $status;
          $fp = fopen("$DATAPATH/$jobid/info.yaml", 'w');
          fwrite($fp, Spyc::YAMLDump($info));
          fclose($fp);
        } */
        

}else{
}

$select = $motif_tmp_filename;
   for($i=0;$i<count($annotation1);$i++)
   {
	   
          if($annotation1[$i]['Motifid']==$id)
          {    
	 
				$this_motif_count =  count($annotation1[$i]['Motifs']);
				$motif_align = array();
				file_put_contents("$ct_path$motif_tmp_filename", ">$motif_tmp_filename".PHP_EOL);
				for($j=0;$j<$this_motif_count;$j++){
					array_push($motif_align,$annotation1[$i]['Motifs'][$j]['Motif']);
					file_put_contents("$ct_path$motif_tmp_filename", $annotation1[$i]['Motifs'][$j]['Motif'].PHP_EOL, FILE_APPEND);
				}
				file_put_contents("$ct_path$motif_tmp_filename", ">end".PHP_EOL, FILE_APPEND);
          	   system("cat $ct_path$motif_tmp_filename |python $TOOLPATH/motif_tools/align2matrix.py > $DATAPATH/$jobid/logo_tmp/$select.matrix");
             system("cat $ct_path$motif_tmp_filename | perl $TOOLPATH/motif_tools/align2uniprobe.pl > $DATAPATH/$jobid/logo_tmp/$select.uniprobe");
             system("cat $DATAPATH/$jobid/logo_tmp/$select.uniprobe | perl $TOOLPATH/motif_tools/uniprobe2meme > $DATAPATH/$jobid/logo_tmp/$select.meme");
                break;
          }
         
   }

        $workdir="$DATAPATH/$jobid";
      $show=array();
      $key=0;$max=0;$lengthseq=array();
	  #background fasta
	     $fp = fopen($motif_background_filename, 'r');
	     while(!feof($fp)) 
	  	   {
	  	  $line=fgets($fp);
	      if(preg_match("/^>/",$line))
	      {$key++;
	     
	      $line=fgets($fp);
	      		if($max<strlen($line)) $max=strlen($line);
	      $show[$key]['len']=strlen($line);
	       $show[$key]['motifs']=array();
	      	}
	  	   }
	  fclose($fp);
   
    $showann=array();


	  	  for($i=0;$i<count($annotation1);$i++)
	  	   {  
	  	   	if($annotation1[$i]['Motifid']==$id)
	  	   	{     $showann[0]=$annotation1[$i];
	  	   		for($z=0;$z<count($annotation1[$i]['Motifs']);$z++)
	  	   		{
	  	   			  
	  	   			  $result=array(
	  	   			  'name'=>$annotation1[$i]['Motifname'],
	  	   			  'start'=>$annotation1[$i]['Motifs'][$z]['start'],
	  	   			  'end'=>$annotation1[$i]['Motifs'][$z]['end'],
                'id'=>$annotation1[$i]['Motifs'][$z]['id'],
	  	   			  );
						   if(1){
							   error_reporting(E_ERROR | E_PARSE);
							   array_push($show[(int)$annotation1[$i]['Motifs'][$z]['Seq']]['motifs'],$result);
						   }
	  	   			  
                //print_r();
	  	   			}
	  	   		
	  	   	}
	  	   	
	  	  }
	  	 

   $_SESSION[$jobid."show"]=$show;
   $ScaleLen=840;
   $GridUnit=5;
   $LabelUnit=10;
   $WinWidth=870;
   $Unit=10;
   $MinLabel=$max/($ScaleLen/$GridUnit);
   $blank=0;
   $imagesrc=array();
  $n=0;
for($i=1;$i<=count($show);$i++)
{    $seqlen=$show[$i]['len'];

	   if($seqlen< $max)
	    {$ScaleLen=$seqlen*($GridUnit/$MinLabel);
	    	$blank=($max-$seqlen);
	    }
	  else{ $ScaleLen=840;$blank=0;}
	 if($show[$i]['motifs']!=null)
		{$imagesrc[$n]=array(
		 'ScaleLen'=>$ScaleLen,
     'GridUnit'=>$GridUnit,
     'LabelUnit'=>$LabelUnit,
     'WinWidth'=>$WinWidth,
     'Unit'=>$Unit,
      'MinLabel'=>$MinLabel,
      'id'=>$i,
      'jobid1'=>$jobid,
      'blank'=>$blank,
		);
		$n++;
		}
		
}

  $matrix="";
    $matrix=$matrix."-----------------------------------------Motif Matrix Format--------------------------------------"."\n";
    if($fp = fopen("$DATAPATH/$jobid/logo_tmp/$select.matrix", 'r')){
	
	   while(!feof($fp)) 
	  	   {
	  	  $line=fgets($fp);
	       $matrix=$matrix.$line;
	  	   }
	
	  fclose($fp);
	}
    $matrix=$matrix."--------------------------------------Motif Uniprobe Format------------------------------------"."\n";
    if( $fp = fopen("$DATAPATH/$jobid/logo_tmp/$select.uniprobe", 'r')){
	   while(!feof($fp)) 
	  	   {
	  	  $line=fgets($fp);
	       $matrix=$matrix.$line;
	  	   }
	  fclose($fp);
	  }
    $matrix=$matrix."---------------------------------------Motif meme Format----------------------------------------"."\n";
       if($fp = fopen("$DATAPATH/$jobid/logo_tmp/$select.meme", 'r')){
	   while(!feof($fp)) 
	  	   {
	  	  $line=fgets($fp);
	       $matrix=$matrix.$line; 
	  	   }
	  fclose($fp);
	   }
$smarty->assign('filename',$filename);
$smarty->assign('jobid',$jobid);
$status="Done";
$smarty->assign('from',$from);
$smarty->assign('id',$id);
$smarty->assign('matrix',$matrix);
$smarty->assign('status',$status);
$smarty->assign('ann', $showann);
$smarty->assign('src', $imagesrc);
$smarty->assign('BOBRO2PATH', $BOBRO2PATH);
$smarty->display('motif_detail.tpl');

?>
