#!/usr/bin/perl
if(open(MYFILE,"$ARGV[0]")&&open(OUTPUT,">similarity"))
{ my $key=0;
	 while($line=<MYFILE>)
	 {
	 if($line =~ /similarity/){
	 	@array=split(/\t/,$line);
	 	print ("\t");
	 	for($i=1;$i<@array-1;$i++)
	 	{print ($array[$i]."\t"); } 
	 	print ($array[$i+1]."\n");
	 	}
	 else {
	 	 $key++;
	 		@array=split(/\t/,$line);
	 		print  ($array[0]."\t");
	 		 	for($i=1;$i<@array-1;$i++)
	 		 	{@array1=split(/ /,$array[$i]);
	 		 		if($i==$key)
	 		 		{print  ("1.00"."\t");}
	 		 		else
	 		 		{print  ($array1[0]."\t");}
	 		 	}
	 		 	@array1=split(/ /,$array[$i+1]);
	 		 	  if(($i+1)==$key)
	 		 		{print  ("1.00"."\t");}
	 		 		else
	 		 		{print  ($array1[0]."\n");}
	 	
	 	}
	 	
	 	
	 }
	 close(OUTPUT);
}
close(MYFILE);