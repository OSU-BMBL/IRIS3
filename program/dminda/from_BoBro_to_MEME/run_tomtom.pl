#!/usr/bin/env perl

use strict;
use warnings;

my $db_d = "/usr/local/meme/latest/db/motif_databases";

my $prodoric = "prodoric.meme";
my $regtransbase = "regtransbase.meme";

my @motifs = glob "*.meme";

foreach (@motifs) {
    /(.*)\.meme/;
    my $nc = $1;
    my $cmd = "tomtom -no-ssc --text -verbosity 1 -min-overlap 5 -dist pearson -evalue -thresh 10 $_ $db_d/$prodoric > $nc.prod";
    print "$cmd\n";
    #system($cmd);

    $cmd = "tomtom -no-ssc --text -verbosity 1 -min-overlap 5 -dist pearson -evalue -thresh 10 $_ $db_d/$regtransbase > $nc.reg";
    print "$cmd\n";
    #system($cmd);

}
