#! /usr/bin/perl -w

($FM, $FP) = @ARGV;

($id, $c1, $header2) = ("", "", "");
$j2 = 0;
open(FP, $FP) or die "ERROR $FP\n";
while(<FP>){
    chomp;
    ($id, $branch) = split(/\t/);
    @b = split(/,/, $branch);
    $cid = pop @b;
    for($j=0; $j<@b; $j++){
	$aid = $b[$j];
	if( ! $aid2j{$aid} ){
	    $aid2j{$aid} = ++$j2;
	    $header2 .= ("\t" . $aid);
	}
	if( ! $hash_ac{$aid}{$cid} ){
	    push( @{$cls2cid{$aid}}, $cid ); 
	    $hash_ac{$aid}{$cid} = 1;
	}
    }
}
$j2_max = $j2;

open(FM, $FM) or die "ERROR $FM\n";
$header = <FM>; chomp $header;
($c1, @colnames) = split(/\t/, $header);
for($j=1; $j<@colnames; $j++){
    $cid2j{ $colnames[$j] } = $j;
    $j_max = $j;    
}
print $header . $header2 . "\n";
while($line = <FM>){
    chomp $line;
    ($rowname, @prof) = split(/\t/, $line);
    foreach my $aid ( keys(%aid2j) ){
	my $c = 0;
	foreach $cid ( @{$cls2cid{$aid}} ){
	    $c += $prof[ $cid2j{$cid} ];
	}
	$prof[ $aid2j{$aid} + $j_max ] = $c;
    }
    $priout = $rowname;
    for($j=0; $j<=$j_max+$j2_max; $j++){
	$priout .= ("\t" . $prof[$j]);
    }
    print $priout . "\n";
}
