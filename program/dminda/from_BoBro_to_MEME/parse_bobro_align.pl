#!/usr/bin/env perl
#
use strict;
use warnings;

my @motif;
my %align;
while(<>) {
    chomp;
    next unless s/^>//;

    my ($n, $seq, $s, $e, $m, $score, $info) = split;
    push @motif, $n;

    push @{$align{$n}}, $m;
}

foreach (keys %align) {
    print ">$_\n";

    print join "\n", @{$align{$_}};
    print "\n";
}

print ">end\n";
