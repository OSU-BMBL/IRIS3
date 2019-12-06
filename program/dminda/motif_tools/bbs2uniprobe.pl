#!/usr/bin/perl
#
# File: bobro2uniprobe.pl
# Description: Transfer a BoBro output file to a simple uniprobe format
#

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Basename;

sub manual {
    print "Transfer a BBS output file to a simple uniprobe format\n";
    print "Usage:\
    perl bobro2uniprobe.pl\
    -i inputfile\
    -o outputfile\
    option:\
    -h print this manual\n";
    die;
}


my %opt;
getopt("i:o:h", \%opt);

manual if $opt{h};
manual unless ($opt{i} and $opt{o});


my $cutoff = 100;
my $motif_id;
my %pos_weight_matrix;
my @aligned_motif;

open OUT, ">$opt{o}" or die "Cannot open $opt{o}:$!";

open IN, "$opt{i}" or die "Cannot open $opt{i}:$!";
while(<IN>) {
    chomp;
    if (/^ Motif-([0-9]+)$/) { # a new motif found
        my $num = $1;
        $motif_id = "Motif-$num";
        conditional_motif_output();
    }elsif(/^>/) {
        my $seq = (split)[3];
        push @aligned_motif, $seq;
    }else {
        next;
    }
}
conditional_motif_output(); # check if there is a unprinted motif 
close IN;
close OUT;

sub conditional_motif_output {
    my $matrix = { A => [], C => [], G => [], T => [] };
    if ($motif_id and @aligned_motif) {

        #print Dumper \@aligned_motif;

        my $seq_num = @aligned_motif;
        my $seq_length = length($aligned_motif[0]);

        foreach (values %$matrix) {
            for(my $i = 0; $i < $seq_length; $i++) {
                $$_[$i] = 0;
            }
        }

        foreach my $seq (@aligned_motif) {
            for (my $i = 0; $i < $seq_length; $i++) {
                my $letter = substr($seq, $i, 1);
                if($letter eq 'N') { # if 'N' encountered, treat as equally ATGC
                    $matrix->{'A'}[$i] += 0.25;
                    $matrix->{'T'}[$i] += 0.25;
                    $matrix->{'G'}[$i] += 0.25;
                    $matrix->{'C'}[$i] += 0.25;
                } else {
                    $matrix->{$letter}[$i]++;
                }
            }
        }

        foreach (values %$matrix) {
            foreach (@$_) {
                $_ /= $seq_num;
            }
        }

        # print the motif out
        print OUT "\n$motif_id\n\n";
        foreach my $ltt (keys %$matrix) {
            print OUT "$ltt:";
            print OUT map { "\t$_" } @{$matrix->{$ltt}};
            print OUT "\n";
        }
        $motif_id = '';
        @aligned_motif = ();
    }
#    print Dumper $matrix;

}
