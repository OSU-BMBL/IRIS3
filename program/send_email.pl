#!/usr/bin/perl
if(@ARGV!=3){
        die("Usage: send_eemail.pl <job_id$ARGV[0]> <to_email$ARGV[1]> <message_file$ARGV[2]>\n")
}


use Mail::Sendmail qw(sendmail %mailcfg);

my $job_id=shift;
my $email=shift;
my $message_file=shift;
open FILE,"$message_file" or die "Can not open file: $message_file\n";
my @lines=<FILE>;
close FILE;
my $message=join("",@lines);

my %mail = ( To      => $email,
			 Bcc     => 'flykun0620@gmail.com','maqin2001@gmail.com','anjun.ma@osumc.edu',
             From    => 'IRIS3 <no-reply@bmbl.bmi.osumc.edu>',
             Subject => "Information from Job $job_id on IRIS3",'Content-Type' => 'text/html',
             Message => $message
           );
sendmail(%mail) or die $Mail::Sendmail::error;
