$jobid = $ARGV[0];


open CC,"/var/www/html/iris3/data/".$jobid."/email.txt" or die "Can't open : $!";
$line_email = <CC>;
chomp($line_email);
close(CC);
$email_content = "<table class='body' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%; background-color: #f6f6f6;' border='0' cellspacing='0' cellpadding='0'>
<tbody>
<tr>
<td style='font-family: sans-serif; font-size: 14px; vertical-align: top;'>&nbsp;</td>
<td class='container' style='font-family: sans-serif; font-size: 14px; vertical-align: top; display: block; margin: 0 auto; max-width: 700px; padding: 10px; width: 700px;'>
<div class='content' style='box-sizing: border-box; display: block; margin: 0 auto; max-width: 700px; padding: 10px;'><!-- START CENTERED WHITE CONTAINER --> <span class='preheader' style='color: transparent; display: none; height: 0; max-height: 0; max-width: 0; opacity: 0; overflow: hidden; mso-hide: all; visibility: hidden; width: 0;'><g class='gr_ gr_65 gr-alert gr_spell gr_inline_cards gr_run_anim ContextualSpelling ins-del multiReplace' id='65' data-gr-id='65'>DMINDA</g> job finished</span>
<table class='main' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%; background: #ffffff; border-radius: 3px;'><!-- START MAIN CONTENT AREA -->
<tbody>
<tr>
<td class='wrapper' style='font-family: sans-serif; font-size: 14px; vertical-align: top; box-sizing: border-box; padding: 20px;'><br />
<table style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%;' border='0' cellspacing='0' cellpadding='0'>
<tbody>
<tr>
<td style='font-family: sans-serif; font-size: 14px; vertical-align: top;'>
<table border='0' width='100%' cellspacing='0' cellpadding='0'>
<tbody>
<tr>
<td class='subhead'>Hello,</td>
</tr>
<tr>
<td class='h1' style='padding: 5px 0 0 0;'><br />
<div>
<div><span>Your IRIS3 job is done.<br /><br /></span><span>Your email: $line_email </span></div>
</div>
</td>
</tr>
</tbody>
</table>
<p style='font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;'></p>
<table class='btn btn-primary' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%; box-sizing: border-box;' border='0' cellspacing='0' cellpadding='0'>
<tbody>
<tr>
<td style='font-family: sans-serif; font-size: 14px; vertical-align: top; padding-bottom: 15px;' align='left'>
<table style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: auto;' border='0' cellspacing='0' cellpadding='0'>
<tbody>
<tr>
<td style='font-family: sans-serif; font-size: 14px; vertical-align: top; background-color: #3498db; border-radius: 5px; text-align: center;'><a style='display: inline-block; color: #ffffff; background-color: #3498db; border: solid 1px #3498db; border-radius: 5px; box-sizing: border-box; cursor: pointer; text-decoration: none; font-size: 14px; font-weight: bold; margin: 0; padding: 12px 25px; text-transform: capitalize; border-color: #3498db;' href='https://bmbl.bmi.osumc.edu/iris3/results.php?jobid=$jobid' target='_blank' rel='noopener'>Click to Check your result</a></td>
</tr>
</tbody>
</table>
<br />
<table>
<tbody>
<tr>
<td>
<p>If you&rsquo;re having trouble clicking the button, copy and paste the URL below into your web browser:</p>
</td>
</tr>
</tbody>
</table>
<span>&nbsp;</span><span>https://bmbl.bmi.osumc.edu/iris3/results.php?jobid=$jobid<br /></span></td>
</tr>
</tbody>
</table>


</td>
</tr>
</tbody>
</table>
</td>
</tr>
<!-- END MAIN CONTENT AREA --></tbody>
</table>
<!-- START FOOTER -->
<div class='footer' style='clear: both; margin-top: 10px; text-align: center; width: 100%;'>
<table style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%;' border='0' cellspacing='0' cellpadding='0'>
<tbody>
<tr>
<td class='content-block' style='font-family: sans-serif; vertical-align: top; padding-bottom: 10px; padding-top: 10px; font-size: 12px; color: #999999; text-align: center;'><span>Copyright 2018 &copy; </span><a href='https://www.sdstate.edu/agronomy-horticulture-plant-science/bioinformatics-and-mathematical-biosciences-lab' target='_blank' rel='noopener'>BMBL</a><span>, </span><a href='http://prod.sdstate.edu/' target='_blank' rel='noopener'>SDSU</a><span>. All rights reserved. </span></td>
</tr>
<tr>
<td class='content-block powered-by' style='font-family: sans-serif; vertical-align: top; padding-bottom: 10px; padding-top: 10px; font-size: 12px; color: #999999; text-align: center;'><a href='mailto:qin.ma\@osumc.edu' title='qin.ma\@osumc.edu'>Contact us: qin.ma\@osumc.edu</a><span> </span></td>
</tr>
</tbody>
</table>
</div>
<!-- END FOOTER --> <!-- END CENTERED WHITE CONTAINER --></div>
</td>
<td style='font-family: sans-serif; font-size: 14px; vertical-align: top;'>&nbsp;</td>
</tr>
</tbody>
</table>";
$message_file = "/var/www/html/iris3/data/".$jobid."/message_file.txt";
open CA,">$message_file";
print CA "$email_content";
close CA;

system("perl /var/www/html/iris3/program/send_email.pl $jobid $line_email $message_file");
