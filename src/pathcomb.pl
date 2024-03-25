#! /usr/bin/perl -w

($FH, $FP, $FE) = @ARGV;
$INI_C = "C";
$INI_H = "H";

($id, $name) = ("", "");
open(FH, $FH) or die "ERROR $FH\n";
while(<FH>){
    chomp;
    if(/^\[Term\]/){
        ($id, $name) = ("", "");
    }elsif(/^id\: CHEMONTID:(\d+)$/){
        $id = $1;
    }elsif(/^name\: (\S.+)$/){
        $name = $1;
    }elsif(/^is_a\: CHEMONTID:(\d+) /){
	$pid = $1;
	next if $pid eq "9999999";
	$pid = "root" if $pid eq "0000000";
	$pid = "root_i" if $pid eq "0000001";
	$parent{$id} = $pid;
    }
}

foreach $id ( keys(%parent) ){
    $branch = &find_anc($id);
    $branch =~ s/,$//;
    $id2branch{$id} = $branch;
}

open(FE, $FE) or die "ERROR $FE\n";
$header = <FE>; chomp $header;
foreach my $cid ( split(/\t/, $header) ){
    next if $cid !~ /^C\d+$/;
    $hash_cid{$cid} = 1;
}

$i = 0;
open(FP, $FP) or die "ERROR $FP\n";
while(<FP>){
    chomp;
    ($cid, $id) = split(/\t/);
    $cid = $INI_C . $cid if $cid =~/^\d+$/;
    next if ! $hash_cid{$cid};
    $myid = $cid . "_" . ++$i;
    next if $id2branch{$id} =~ /^H0000001/; # Inorganic compounds
    print join("\t", ($myid, $id2branch{$id} . "," . $cid)) . "\n";
}


sub find_anc {
    my ($id) = @_;
    my $branch = $INI_H . $id . ",";
    return ("root," . $branch) if $parent{$id} eq "root";
    return ("root_i," . $branch) if $parent{$id} eq "root_i";
    if( $parent{$id} ){
	$branch = &find_anc($parent{$id}) . $branch;
    }
    return $branch;
}
