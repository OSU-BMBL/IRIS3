<?php
require('config/common.php');

header ('Content-type: image/png');
$ScaleLen=$_GET[ScaleLen];
$GridUnit=$_GET[GridUnit];
$LabelUnit=$_GET[LabelUnit];
$MinLabel=$_GET[MinLabel];
$Unit=$_GET[Unit];
$WinWidth=$_GET[WinWidth];
$color=$_GET[color];
$id=$_GET[id];
$blank=$_GET[blank];
$jobid1=$_GET[jobid1];

session_start();
$motifs=$_SESSION[$jobid1."show"];
$key=0;
$nup=0;
$ndown=0;
$donup=array();
$dondown=array();
	for($j=0;$j<count($motifs[$id]['motifs']);$j++)
	{   
		 $start=(int)$motifs[$id]['motifs'][$j]['start'];
		     $end=(int)$motifs[$id]['motifs'][$j]['end'];
		   	if($start> $end && $dondown[(int)$motifs[$id]['motifs'][$j]['id']-1]==null )  	
		   	{$ndown++;
		   	$dondown[(int)$motifs[$id]['motifs'][$j]['id']-1]=$ndown;
		
		    }else if($donup[(int)$motifs[$id]['motifs'][$j]['id']-1]==null){
		    	$nup++;
		   	$donup[(int)$motifs[$id]['motifs'][$j]['id']-1]=$nup;
		  	}
		 
		
   }
   $ScaleAreaHeight=($nup+$ndown)*15+40;
   if($blank!=0)
{$x=$blank*($GridUnit/$MinLabel);}
else{$x=0;}                    //satrtx
$y=$nup*15+15;   //central y
$thick = 0.5;
$im = @ImageCreate ($WinWidth+40,$ScaleAreaHeight) or die ("Cannot Initialize new GD image stream");
$background_color = ImageColorAllocate ($im, 255, 255, 255);
$text_color = ImageColorAllocate ($im, 33, 14, 91);
$line_color = ImageColorAllocate ($im, 0, 0, 0);
$numColor = ImageColorAllocate ($im, 200, 10, 10);
$gene_color=ImageColorAllocate ($im,128,128,128);
//ImageString($im,3,100,3,$ScaleLen,$numColor); 
//ImageString($im,3,10,3,$MinLabel,$numColor);

ImageFilledRectangle($im,$x,$y,$x+$ScaleLen,$y+$thick,$line_color);
ImageFilledRectangle($im,$WinWidth-30,$y-20,$WinWidth,$y,$gene_color);
for($i=0; $i<$ScaleLen-5; $i+=$GridUnit) {
	if($i%($GridUnit*$LabelUnit)==0) {
		Imageline($im,$x+$i,$y-7,$x+$i,$y,$line_color);
		ImageString($im,2,$x+$i,$y-18,(int)(($i*$MinLabel*$Unit)/($GridUnit*$LabelUnit)),$numColor); 
	}  else {
		Imageline($im,$x+$i,$y-5,$x+$i,$y,$line_color);
	}
}  

	for($j=0;$j<count($motifs[$id]['motifs']);$j++)
	{       if(intval($color)==0)
          {$motif_color = ImageColorAllocate ($im, (int)$motifs[$id]['motifs'][$j]['id']*100,(int)$motifs[$id]['motifs'][$j]['id']*10,(int)$motifs[$id]['motifs'][$j]['id']/2);
          } else {
          $motif_color = ImageColorAllocate ($im, 240, 50, 10);
          }
	     	 $start=(int)$motifs[$id]['motifs'][$j]['start'];
		     $end=(int)$motifs[$id]['motifs'][$j]['end'];
	      
         if($start> $end)
             {$key=$dondown[(int)$motifs[$id]['motifs'][$j]['id']-1];
             	ImageFilledRectangle($im,$x+$start*$GridUnit/$MinLabel,$y+$key*15,$x+$end*$GridUnit/$MinLabel,$y+15+$key*15,$motif_color);
             # ImageString($im,6,$x+$start/$MinLabel*$GridUnit+2,$y+$key*15,$motifs[$id]['motifs'][$j]['name'],$line_color);
             }
         else
             {$key=$donup[(int)$motifs[$id]['motifs'][$j]['id']-1];
             	ImageFilledRectangle($im,$x+$start*$GridUnit/$MinLabel,$y-$key*15,$x+$end*$GridUnit/$MinLabel,$y-15-$key*15,$motif_color);
              #ImageString($im,6,$x+$end/$MinLabel*$GridUnit+2,$y-15-$key*15,$motifs[$id]['motifs'][$j]['name'],$line_color);
             }
      
     
        
 	
 	
}

//header ("Content-type: image/png");
ImagePng ($im);
ImageDestroy($im);
?>
