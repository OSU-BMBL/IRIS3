#!/usr/bin/env perl
# bbs align format to separate fasta format mainly for weblogo drawing.
#
use strict;
use warnings;

my $output_d = ".";
my $id;
while(<>) {
    chomp;
    if(s/^>//) {
        $id = $_;
        if($_ eq 'end') {next;}
        my $f = (split /\s+/, $_)[0];
        open OUT, ">$f.fasta" or die "Cannot open $f: $!";
    } else {
        print OUT ">$id\n", "$_\n";
    }
}

