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
    print "Transfer a BoBro align file to a simple uniprobe format\n";
    print "Usage: cat <motif align> | perl $0 > <output file>\n";
    die;
}



my $cutoff = 100;
my $file;
my $motif_id;  # use file_num as the motif id
my %pos_weight_matrix;
my @aligned_motif;
my $motif_flag = 0;


while(<>) {
    chomp;
    if(s/^>//) {
        conditional_motif_output();
        $motif_id = $_;
    } else {
        push @aligned_motif, $_;
    }
}
conditional_motif_output(); # check if there is a unprinted motif 

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
        print "\n$motif_id\n\n";
        foreach my $ltt (keys %$matrix) {
            print "$ltt:";
            print map { "\t".sprintf("%.2f",$_) } @{$matrix->{$ltt}};
            print "\n";
        }
        $motif_id = '';
        @aligned_motif = ();
    }
#    print Dumper $matrix;
}
