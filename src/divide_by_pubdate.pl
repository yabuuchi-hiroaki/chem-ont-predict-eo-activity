#! /usr/bin/perl -w

($F, $YR, $FW1, $FW2) = @ARGV;

open(FW1, "> $FW1") or die "ERROR $FW1\n";
open(FW2, "> $FW2") or die "ERROR $FW2\n";

open(F, $F) or die "ERROR $F\n";
$header = <F>; chomp $header;
@headers = split(/\t/, $header);
shift @headers; $headers[0] = "";
print FW1 join("\t", @headers) . "\n";
print FW2 join("\t", @headers) . "\n";
while($line = <F>){
    chomp $line;
    ($id, $y, @prof) = split(/\t/, $line);
    if($y eq ""){
	print STDERR "WARNING: unknown pubdate id = $id\n";
	next;
    }
    if($y <= $YR ){
        print FW1 join("\t", ($id, @prof)) . "\n";
    }else{
	print FW2 join("\t", ($id, @prof)) . "\n";
    }
}
