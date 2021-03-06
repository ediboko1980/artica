#! /usr/bin/perl
# ---------------------------------------------------------------------------
#
# USAGE: rsyncstats <options>
#
# OPTIONS:
#       -f <filename>   Use <filename> for the log file
#       -h		include report on hourly traffic
#       -d		include report on domain traffic
#       -t		report on total traffic by section
#       -D <domain>     report only on traffic from <domain>
#       -l <depth>      Depth of path detail for sections
#       -s <section>    Section to report on, For example: -s /pub will report
#				only on paths under /pub
#
# This script parses the default logfile format produced by rsync when running
# as a daemon with transfer logging enabled. It is derived from the xferstats
# script that comes with wuftpd
#
# Andrew Tridgell, October 1998
# rsync-bugs@samba.org
#
# ---------------------------------------------------------------------------

# edit the next line to customize for your default log file
$usage_file = "/var/adm/rsyncd.log";

# Edit the following lines for default report settings.
# Entries defined here will be over-ridden by the command line.

$opt_h = 1; 
$opt_d = 0;
$opt_t = 1;
$opt_l = 2;

require 'getopts.pl';
&Getopts('f:rahdD:l:s:');

if ($opt_r) { $real = 1;}
if ($opt_a) { $anon = 1;}
if ($real == 0 && $anon == 0) { $anon = 1; }
if ($opt_f) {$usage_file = $opt_f;}

open (LOG,$usage_file) || die "Error opening usage log file: $usage_file\n";

if ($opt_D) {print "Transfer Totals include the '$opt_D' domain only.\n";
	     print "All other domains are filtered out for this report.\n\n";}

if ($opt_s) {print "Transfer Totals include the '$opt_s' section only.\n";
	     print "All other sections are filtered out for this report.\n\n";}

line: while (<LOG>) {

   @line = split;

   $day = $line[0];
   $time = $line[1];
   $pid = $line[2];
   $op = $line[3];
   $host = $line[4];
   $ip = $line[5];
   $module = $line[6];
   $user = $line[7];
   $file = $line[8];
   $bytes = $line[9];

   next if ($#line != 9);

   next if ($op != "send" && $op != "recv");

   $daytime = $day;
   $hour = substr($time,0,2); 

   $file = $module . "/" . $file;

   $file =~ s|//|/|mg;

   @path = split(/\//, $file);

   $pathkey = "";
   for ($i=0; $i <= $#path && $i <= $opt_l;$i++) {
	$pathkey = $pathkey . "/" . $path[$i];
   }

   next if (substr($pathkey,0,length("$opt_s")) ne "$opt_s");

   $host =~ tr/A-Z/a-z/;

   @address = split(/\./, $host);

   $domain = $address[$#address];
   if ( int($address[0]) > 0 || $#address < 2 )
      { $domain = "unresolved"; }

   if ($opt_D) {
       next unless (substr($domain,0,length("$opt_D")) eq "$opt_D");
   }


#   printf ("c=%d day=%s bytes=%d file=%s path=%s\n", 
#	   $#line, $daytime, $bytes, $file, $pathkey);

   $xferfiles++;                                # total files sent
   $xfertfiles++;                               # total files sent
   $xferfiles{$daytime}++;                      # files per day
   $groupfiles{$pathkey}++;                     # per-group accesses
   $domainfiles{$domain}++;

   $xferbytes{$daytime}   += $bytes;          # bytes per day
   $domainbytes{$domain}  += $bytes;		# xmit bytes to domain
   $xferbytes             += $bytes;          # total bytes sent
   $groupbytes{$pathkey}  += $bytes;          # per-group bytes sent

   $xfertfiles{$hour}++;                        # files per hour
   $xfertbytes{$hour}     += $bytes;          # bytes per hour
   $xfertbytes            += $bytes;          # total bytes sent
}
close LOG;

@syslist = keys(systemfiles);
@dates = sort datecompare keys(xferbytes);

if ($xferfiles == 0) {die "There was no data to process.\n";}


print "TOTALS FOR SUMMARY PERIOD ", $dates[0], " TO ", $dates[$#dates], "\n\n";
printf ("Files Transmitted During Summary Period  %12.0f\n", $xferfiles);
printf ("Bytes Transmitted During Summary Period  %12.0f\n", $xferbytes); 
printf ("Systems Using Archives                   %12.0f\n\n", $#syslist+1);

printf ("Average Files Transmitted Daily          %12.0f\n",
   $xferfiles / ($#dates + 1));
printf ("Average Bytes Transmitted Daily          %12.0f\n",
   $xferbytes / ($#dates + 1));

format top1 =

Daily Transmission Statistics

                 Number Of    Number of   Percent Of  Percent Of
     Date        Files Sent   MB  Sent    Files Sent  Bytes Sent
---------------  ----------  -----------  ----------  ----------
.

format line1 =
@<<<<<<<<<<<<<<  @>>>>>>>>>  @>>>>>>>>>>  @>>>>>>>    @>>>>>>>  
$date,           $nfiles,    $nbytes/(1024*1024), $pctfiles,  $pctbytes
.

$^ = top1;
$~ = line1;

foreach $date ( sort datecompare keys(xferbytes) ) {

   $nfiles   = $xferfiles{$date};
   $nbytes   = $xferbytes{$date};
   $pctfiles = sprintf("%8.2f", 100*$xferfiles{$date} / $xferfiles);
   $pctbytes = sprintf("%8.2f", 100*$xferbytes{$date} / $xferbytes);
   write;
}

if ($opt_t) {
format top2 =

Total Transfers from each Archive Section (By bytes)

                                                           - Percent -
     Archive Section                   NFiles     MB      Files   Bytes
------------------------------------- ------- ----------- ----- -------
.

format line2 =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>> @>>>>>>>>>> @>>>>   @>>>>
$section,                 $files,    $bytes/(1024*1024),     $pctfiles, $pctbytes
.

$| = 1;
$- = 0;
$^ = top2;
$~ = line2;

foreach $section ( sort bytecompare keys(groupfiles) ) {

   $files = $groupfiles{$section};
   $bytes = $groupbytes{$section};
   $pctbytes = sprintf("%8.2f", 100 * $groupbytes{$section} / $xferbytes);
   $pctfiles = sprintf("%8.2f", 100 * $groupfiles{$section} / $xferfiles);
   write;

}

if ( $xferfiles < 1 ) { $xferfiles = 1; }
if ( $xferbytes < 1 ) { $xferbytes = 1; }
}

if ($opt_d) {
format top3 =

Total Transfer Amount By Domain

             Number Of    Number of    Percent Of  Percent Of
Domain Name  Files Sent    MB Sent     Files Sent  Bytes Sent
-----------  ----------  ------------  ----------  ----------
.

format line3 =
@<<<<<<<<<<  @>>>>>>>>>  @>>>>>>>>>>>  @>>>>>>>    @>>>>>>>  
$domain,     $files,     $bytes/(1024*1024), $pctfiles,  $pctbytes
.

$- = 0;
$^ = top3;
$~ = line3;

foreach $domain ( sort domnamcompare keys(domainfiles) ) {

   if ( $domainsecs{$domain} < 1 ) { $domainsecs{$domain} = 1; }

   $files = $domainfiles{$domain};
   $bytes = $domainbytes{$domain};
   $pctfiles = sprintf("%8.2f", 100 * $domainfiles{$domain} / $xferfiles);
   $pctbytes = sprintf("%8.2f", 100 * $domainbytes{$domain} / $xferbytes);
   write;

}

}

if ($opt_h) {

format top8 =

Hourly Transmission Statistics

                 Number Of    Number of   Percent Of  Percent Of
     Time        Files Sent    MB  Sent   Files Sent  Bytes Sent
---------------  ----------  -----------  ----------  ----------
.

format line8 =
@<<<<<<<<<<<<<<  @>>>>>>>>>  @>>>>>>>>>>  @>>>>>>>    @>>>>>>>  
$hour,           $nfiles,    $nbytes/(1024*1024), $pctfiles,  $pctbytes
.


$| = 1;
$- = 0;
$^ = top8;
$~ = line8;

foreach $hour ( sort keys(xfertbytes) ) {

   $nfiles   = $xfertfiles{$hour};
   $nbytes   = $xfertbytes{$hour};
   $pctfiles = sprintf("%8.2f", 100*$xfertfiles{$hour} / $xferfiles);
   $pctbytes = sprintf("%8.2f", 100*$xfertbytes{$hour} / $xferbytes);
   write;
}
}
exit(0);

sub datecompare {
    $a gt $b;
}

sub domnamcompare {

   $sdiff = length($a) - length($b);
   ($sdiff < 0) ? -1 : ($sdiff > 0) ? 1 : ($a lt $b) ? -1 : ($a gt $b) ? 1 : 0;

}

sub bytecompare {

   $bdiff = $groupbytes{$b} - $groupbytes{$a};
   ($bdiff < 0) ? -1 : ($bdiff > 0) ? 1 : ($a lt $b) ? -1 : ($a gt $b) ? 1 : 0;

}

sub faccompare {

   $fdiff = $fac{$b} - $fac{$a};
   ($fdiff < 0) ? -1 : ($fdiff > 0) ? 1 : ($a lt $b) ? -1 : ($a gt $b) ? 1 : 0;

}


