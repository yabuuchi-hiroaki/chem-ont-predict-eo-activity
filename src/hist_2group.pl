#! /usr/bin/perl -w

($FM) = @ARGV;

open(FM, $FM) or die "ERROR $FM\n";
$header = <FM>; chomp $header;
($c1, @colnames) = split(/\t/, $header);
$i = -1;
while($line = <FM>){
    chomp $line;
    $i++;
    ($c1, @{$mat[$i]}) = split(/\t/, $line);
}
$i_max = $i;

for($j=1; $j<@colnames; $j++){
    my ($h1, $h2) = ("", "");
    my ($sum_h1, $sum_h2) = (0, 0);
    for($i=0; $i<=$i_max; $i++){
	$comp = $mat[$i][$j];
        if( $mat[$i][0] == 1 ){
	    $h1 .= "$comp\,";
	    $sum_h1 += $comp;
	}else{
	    $h2 .= "$comp\,";
            $sum_h2 += $comp;
        }
    }
    $h1 =~ s/,$//; $h2 =~ s/,$//;
    print join("\t", ($colnames[$j], $h1, $h2)) . "\n";
}
