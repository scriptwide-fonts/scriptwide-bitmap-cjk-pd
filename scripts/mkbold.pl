#!/usr/bin/env perl
# $Id: mkbold,v 1.2 2002/09/14 20:34:39 euske Exp $
#
#  -- makes BDF font bold
#	programmed by NAGAO, Sadakazu <snagao@cs.titech.ac.jp>	
#	modified by Yasuyuki Furukawa <yasu@on.cs.keio.ac.jp>	
#		* public domain *
#

$bdir = 1;			# left
$pile = 0;			# right

$verbose = 0;
$verbose_min = 100;

for $opt (@ARGV) {
    if ($opt =~ /^-/) {	# option
	$bdir = 0 if $opt eq '-r';	# right
	$bdir = 1 if $opt eq '-l';	# left
	$pile = 0 if $opt eq '-R';	# right
	$pile = 1 if $opt eq '-L';	# left
	$verbose = 1 if $opt eq '-V';	# verbose
	next;
    } else {
	$file = $opt;
	last;
    }
}
$file= "-" unless $file;

open F, $file || die;

$col = int(`stty  -F /dev/tty size 2>/dev/null | sed 's/.* //'`) || 80;

$ch_count = 0;

@vmeter = ("|", "\\", "-", "/");

while (<F>) {

    if (/^FONT[ \t]/ || /^WEIGHT_NAME/) {
	s/Medium/Bold/;
	print;
	next;
    }

    if (/^CHARS[ \t]/) {
	$max_chars = substr($_, 6);
    }

    if (/^BITMAP/) {
	$bitmap = 1;
	print;
	next;
    }

    if (/^ENDCHAR/) {
	$bitmap = 0;
	print;

	if (($ch_count++ % 20) == 0 && $verbose != 0 && $max_chars > $verbose_min) {
	    $n = int($ch_count * 100 / $max_chars);
	    $m = int($n * ($col - 21) / 100);
	    $l = $col - 20 - $m;
	    printf STDERR "\rprogress|" . rstr("=", $m) . rstr(" ", $l) . "$n%%" . $vmeter[$ch_count2++ % 4] 
	}
	next;
    }

    if ($bitmap) {
	chop;
	$l = (length($_) / 2) - 1;

	if ($bdir) {		# left
	    for $i (0..$l) {
		$d[$i] = hex(substr($_, $i*2, 2));
	    }
	    shl(\@bold, \@d, $l);
	} else {
	    for $i (0..$l) {	# right
		$bold[$i] = hex(substr($_, $i*2, 2));
	    }
	    shr(\@d, \@bold, $l);

	}

	if ($pile) {		# left
	    shl(\@tmp, \@bold, $l);
	    bitcalc(\@d, \@tmp, \@d, \@bold, $l);
	} else {		# right
	    shr(\@tmp, \@d, $l);
	    bitcalc(\@d, \@tmp, \@bold, \@d, $l);
	}

	# print
	for $i (0..$l) {
	    printf "%02x", $d[$i];
	}

	print "\n";
	next;
    }

    print;

}
close F;

if ($verbose != 0 && $max_chars > $verbose_min) {
    printf STDERR "\r" . rstr(" ", $col - 3) . "\r";
}

exit 0;

sub shl {
    my ($dout, $din, $size) = @_;
    my $c = 0, $d, $i;
    for ($i = $size; $i >= 0; $i--) {
	$d = $c;
	$c = ($din->[$i] & 0x80) >> 7;
	$dout->[$i] = (($din->[$i] << 1) & 0xff) | $d;
    }
}

sub shr {
    my ($dout, $din, $size) = @_;
    my $c = 0, $d, $i;
    for $i (0..$size) {
	$d = $c;
	$c = ($din->[$i] & 0x01) << 7;
	$dout->[$i] = ($din->[$i] >> 1) | $d;
    }
}

sub bitcalc {
    my ($out, $d1, $d2, $d3, $size) = @_;
    for $i (0..$size) {
	$out->[$i] = ~$d1->[$i] & $d2->[$i] | $d3->[$i];
    }
}

sub rstr # (s, n)
{
    my($s, $n) =  @_;
    my $r = "";

    for (1 .. $n) {
	$r = $s . $r;
    }
    return $r;
}
