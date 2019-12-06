# wrapper for bbr and bbs
use strict;
use warnings;


sub read_bbr_seed {
    my $f = pop;
    my %h;

    open IN, $f or die "Cannot open $f: $!";

    my $motif_now ;
    my $seed_flag = 0;
    my @seeds;

    while(<IN>) {
        chomp;
        if( /Candidate Motif\s*([0-9]+)$/ ) {

            #print map {"$_\n"} @seeds;
            $h{$motif_now} = [ @seeds ] if @seeds;

            $motif_now = "Motif-$1";
            #print "$motif_now\n";

        } elsif ( /Motif Seed/ ) {
            #print "$_\n";
            $seed_flag = 1;
        } elsif ( /^$/ ) {
            $seed_flag = 0;
        } elsif( $seed_flag ) {
            #print "$_\n";
            push @seeds, $_;
        } else {
            next;
        }

    }
    close IN;
    return %h;
}


sub read_bbs_motif {
    my ($file) = @_;

    #my ($p, $z, $e);

    my $info;
    my $motif_now;
    open IN, $file or warn "Cannot open $file: $!";
    while(<IN>) {
	chomp;
	if (/^>(Motif-\d+)/) {
	    my ($name, $seq, $s, $motif, $e, $score, $from) = split;
	    $name = $1;
	    push @{$info->{$name}{'record'}} , $_;
	    push @{$info->{$name}{'from'}}, $from;
	    push @{$info->{$name}{'motif'}}, $motif;
	} else {
	    next;
	}
    }
    close IN;

    return $info;

}

sub read_bbs_stat {
    my ($file) = @_;

    my $info;
    my $motif_now;
    open IN, $file or warn "Cannot open $file: $!";
    while(<IN>) {
	chomp;
	if(/Zscore:\s+(.*)$/) {
	    $info->{$motif_now}{'zscore'} = $1;
	} elsif(/Enrichment:\s+(.*)$/) {
	    $info->{$motif_now}{'enrichment'} = $1;
	} elsif (/Pvalue:\s+(.*)$/) {
	    $info->{$motif_now}{'pvalue'} = $1;
	} elsif (/Consensus:\s+(.*)$/) {
	    $info->{$motif_now}{'consensus'} = $1;
	} elsif (/Motif length:\s+(.*)$/) {
	    $info->{$motif_now}{'length'} = $1;
	} elsif (/Binding sites number:\s+(.*)$/) {
	    $info->{$motif_now}{'number'} = $1;
	} elsif (/^ (Motif-\d+)/) {
	    $motif_now = $1;
	} else {
	    next;
	}
    }
    close IN;

    return $info;
}

sub read_single_bbs_stat {
    my ($file) = @_;

    my $info;
    open IN, $file or warn "Cannot open $file: $!";
    while(<IN>) {
	chomp;
	if(/Zscore:\s+(.*)$/) {
	    $info->{'zscore'} = $1;
	} elsif(/Enrichment:\s+(.*)$/) {
	    $info->{'enrichment'} = $1;
	} elsif (/Pvalue:\s+(.*)$/) {
	    $info->{'pvalue'} = $1;
	} else {
	    next;
	}
    }
    close IN;

    return $info;
}

sub bbr_cmd {
    my ($promoter, $back) = @_;
    my $cmd;
    if ($back) {
	$cmd = "perl ./BBR.pl 2 $promoter $back";
    } else {
	$cmd = "perl ./BBR.pl 1 $promoter ";
    }

    return $cmd;
}

sub write_motif {
    my ($f, $m, @motif) = @_;
    open OUT, ">$f" or die "Cannot open $f: $!";
    print OUT ">$m\n";
    print OUT (join "\n", @motif);
    print OUT "\n";
    print OUT ">end";
}

sub write_alignment {
    my ($f, @motif) = @_;
    open OUT, ">$f" or die "Cannot open $f: $!";
    #print OUT ">$m\n";
    print OUT (join "\n", @motif);
    print OUT "\n";
    #print OUT ">end";
}

sub draw_logo {
    my ($f, $out)  = @_;
    my $cmd;
    if (defined $out) {
	$cmd = "perl script/weblogo/seqlogo -F PNG -a -n -Y -k 1 -c -f $f > $out";
    } else {
	$cmd = "perl script/weblogo/seqlogo -F PNG -a -n -Y -k 1 -c -f $f > $f.png";
    }
    return $cmd;
}


sub bbs_cmd {
    my ($motif, $promoter, $back) = @_;
    my $cmd = "../bin/BBS -i $promoter -j $motif -E";
    $cmd .= " -z $back" if $back;
    return $cmd;
}


1;
