#!./perl
#
#

use Net::Dict;
use lib qw(. ./blib/lib ../blib/lib ./t);
require 'test_host.cfg';

$^W = 1;

my $WARNING;
my %TESTDATA;
my $section;
my @caps;

print "1..17\n";

$SIG{__WARN__} = sub { $WARNING = join('', @_); };

#-----------------------------------------------------------------------
# Build the hash of test data from after the __DATA__ symbol
# at the end of this file
#-----------------------------------------------------------------------
while (<DATA>)
{
    if (/^==== END ====$/)
    {
	$section = undef;
	next;
    }

    if (/^==== (\S+) ====$/)
    {
        $section = $1;
        $TESTDATA{$section} = '';
        next;
    }

    next unless defined $section;

    $TESTDATA{$section} .= $_;
}

#-----------------------------------------------------------------------
# Make sure we have HOST and PORT specified
#-----------------------------------------------------------------------
if (defined($HOST) && defined($PORT))
{
    print "ok 1\n";
}
else
{
    print "not ok 1\n";
}

#-----------------------------------------------------------------------
# constructor with no arguments - should result in a die()
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(); };
if ((not defined $dict) && $@ =~ /takes at least a HOST/)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
}

#-----------------------------------------------------------------------
# pass a hostname of 'undef' we should get undef back
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(undef); };
if (not defined $dict)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}

#-----------------------------------------------------------------------
# pass a hostname of empty string, should get undef back
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(''); };
if (!$@ && not defined $dict && $WARNING =~ /Bad peer address/)
{
    print "ok 4\n";
}
else
{
    print "not ok 4\n";
}

#-----------------------------------------------------------------------
# Ok hostname given, but unknown argument passed.
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($HOST, Foo => 'Bar'); };
if ($@ && !defined $dict && $@ =~ /unknown argument/)
{
    print "ok 5\n";
}
else
{
    print "not ok 5\n";
}

#-----------------------------------------------------------------------
# Ok hostname given, odd number of following arguments passed
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($HOST, 'Foo'); };
if ($@ =~ /odd number of arguments/)
{
    print "ok 6\n";
}
else
{
    print "not ok 6\n";
}

#-----------------------------------------------------------------------
# Ok hostname given, odd number of following arguments passed
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
$WARNING = undef;
eval { $dict = Net::Dict->new($HOST, Port => $PORT); };
if (!$@ && defined $dict && !defined $WARNING)
{
    print "ok 7\n";
}
else
{
    print "not ok 7\n";
}

#-----------------------------------------------------------------------
# Check the serverinfo string.
# We compare this with what we expect to get from dict.org
# We strip off the first two lines, because they have time-varying
# information; but we make sure they're the lines we think they are.
#-----------------------------------------------------------------------
my $serverinfo = $dict->serverInfo();
if (exists $TESTDATA{serverinfo}
    && defined $serverinfo
    && do { $serverinfo =~ s/^dictd.*?\n//s}
    && do { $serverinfo =~ s/^On miranda\.org.*?\n//s}
    && $serverinfo eq $TESTDATA{serverinfo}
   )
{
    print "ok 8\n";
}
else
{
    print STDERR "Test 8, expected string:\n>>\n$TESTDATA{serverinfo}\n<<\nGOT STRING:\n>>\n$serverinfo\n<<\n";
    print "not ok 8\n";
}

#-----------------------------------------------------------------------
# METHOD: status
# call with an argument - should die since it takes no args.
#-----------------------------------------------------------------------
eval { $string = $dict->status('foo'); };
if ($@
    && $@ =~ /takes no arguments/)
{
    print "ok 9\n";
}
else
{
    print "not ok 9\n";
}

#-----------------------------------------------------------------------
# METHOD: status
# call with no args, and check that the general format of the string
# is what we expect
#-----------------------------------------------------------------------
eval { $string = $dict->status(); };
if (!$@
    && defined $string
    && $string
    && $string =~ m!^status \[d/m/c.*\]$!
   )
{
    print "ok 10\n";
}
else
{
    print "not ok 10\n";
}

#-----------------------------------------------------------------------
# METHOD: capabilities
# call with an arg - doesn't take any, and should die
#-----------------------------------------------------------------------
eval { @caps = $dict->capabilities('foo'); };
if ($@
    && $@ =~ /takes no arguments/
   )
{
    print "ok 11\n";
}
else
{
    print "not ok 11\n";
}

#-----------------------------------------------------------------------
# METHOD: capabilities
#-----------------------------------------------------------------------
if ($dict->can('capabilities')
    && eval { @caps = $dict->capabilities(); }
    && do { $string = join(':', sort(@caps)); 1;}
    && $string
    && $string."\n" eq $TESTDATA{'capabilities'}
   )
{
    print "ok 12\n";
}
else
{
    print "not ok 12\n";
}

#-----------------------------------------------------------------------
# METHOD: has_capability
# no argument passed
#-----------------------------------------------------------------------
if ($dict->can('has_capability')
    && do { eval { $dict->has_capability(); }; 1;}
    && $@
    && $@ =~ /takes one argument/
   )
{
    print "ok 13\n";
}
else
{
    print "not ok 13\n";
}

#-----------------------------------------------------------------------
# METHOD: has_capability
# pass two capability names - should also die()
#-----------------------------------------------------------------------
if ($dict->can('has_capability')
    && do { eval { $dict->has_capability('mime', 'auth'); }; 1; }
    && $@
    && $@ =~ /takes one argument/
   )
{
    print "ok 14\n";
}
else
{
    print "not ok 14\n";
}

#-----------------------------------------------------------------------
# METHOD: has_capability
#-----------------------------------------------------------------------
if ($dict->can('has_capability')
    && $dict->has_capability('mime')
    && $dict->has_capability('auth')
    && !$dict->has_capability('foobar')
   )
{
    print "ok 15\n";
}
else
{
    print "not ok 15\n";
}

#-----------------------------------------------------------------------
# METHOD: msg_id
# with an argument - should cause it to die()
#-----------------------------------------------------------------------
if ($dict->can('msg_id')
    && do { eval { $string = $dict->msg_id('dict.org'); }; 1;}
    && $@
    && $@ =~ /takes no arguments/
   )
{
    print "ok 16\n";
}
else
{
    print "not ok 16\n";
}

#-----------------------------------------------------------------------
# METHOD: msg_id
# with no arguments, should get valid id back, of the form <...>
#-----------------------------------------------------------------------
if ($dict->can('msg_id')
    && do { eval { $string = $dict->msg_id(); }; 1;}
    && !$@
    && defined($string)
    && $string =~ /^<[^<>]+>$/
   )
{
    print "ok 17\n";
}
else
{
    print "not ok 17\n";
}


exit 0;

__DATA__
==== serverinfo ====

Database      Headwords         Index          Data  Uncompressed
gcide          203645       3859 kB         12 MB         38 MB
wn             154563       3089 kB       8744 kB         26 MB
moby-thes       30263        528 kB         10 MB         28 MB
elements          130          2 kB         14 kB         45 kB
vera             9203        103 kB        160 kB        558 kB
jargon           2374         42 kB        621 kB       1430 kB
foldoc          13801        268 kB       2142 kB       5898 kB
easton           3968         64 kB       1077 kB       2648 kB
hitchcock        2619         34 kB         33 kB         85 kB
bouvier          6797        128 kB       2338 kB       6185 kB
devils            997         15 kB        161 kB        377 kB
world02           280          5 kB       1543 kB       7172 kB
gazetteer       52994       1087 kB       1754 kB       8351 kB
gaz-county      12875        269 kB        280 kB       1502 kB
gaz-place       51361       1006 kB       1711 kB         13 MB
gaz-zip         33249        454 kB       2122 kB         15 MB
--exit--            0          0 kB          0 kB          0 kB
afr-deu          3802         52 kB         48 kB        140 kB
afr-eng          5130         72 kB         57 kB        175 kB
ara-eng         83872       1953 kB        662 kB       2384 kB
cro-eng         79821       1791 kB       1016 kB       2899 kB
cze-eng           490          6 kB          5 kB         12 kB
dan-eng          3999         54 kB         43 kB        121 kB
deu-eng         81695       1618 kB       1370 kB       4424 kB
deu-fra          8170        120 kB         82 kB        252 kB
deu-ita          4456         64 kB         38 kB        119 kB
deu-nld         12814        201 kB        193 kB        582 kB
deu-por          8731        131 kB        107 kB        314 kB
eng-afr          6398         85 kB         59 kB        192 kB
eng-ara         83879       1349 kB        667 kB       2466 kB
eng-cro         59211       1220 kB        971 kB       2706 kB
eng-cze        150010       2482 kB       1463 kB       8478 kB
eng-deu         93282       1717 kB       1401 kB       4537 kB
eng-fra          8804        130 kB        134 kB        370 kB
eng-hin         25647        419 kB       1062 kB       3274 kB
eng-hun         87960       1848 kB       1812 kB       4927 kB
eng-iri          2719         35 kB         30 kB         83 kB
eng-ita          4521         59 kB         40 kB        128 kB
eng-lat          3028         40 kB         39 kB        114 kB
eng-nld          7716        121 kB        166 kB        478 kB
eng-por         37450        570 kB        540 kB       1574 kB
eng-rom           992         14 kB         14 kB         42 kB
eng-rus          3387         46 kB         41 kB        135 kB
eng-spa          5909         84 kB         86 kB        250 kB
eng-swa          1458         18 kB         11 kB         37 kB
eng-swe          5485         76 kB         79 kB        221 kB
eng-tur         36597        580 kB       1687 kB       4238 kB
eng-wel          2123         27 kB         25 kB         68 kB
fra-deu          6116         90 kB        105 kB        286 kB
fra-eng          7833        121 kB        122 kB        344 kB
fra-nld          9606        153 kB        194 kB        544 kB
hin-eng         32971       1227 kB       1062 kB       3274 kB
hun-eng        139943       3350 kB       2276 kB       7134 kB
iri-eng          1187         16 kB         12 kB         31 kB
ita-deu          2925         40 kB         36 kB         89 kB
jpn-deu           454          6 kB          5 kB         13 kB
kha-deu          1015         13 kB         12 kB         35 kB
lat-deu          1800         24 kB         20 kB         58 kB
lat-eng          2306         31 kB         24 kB         71 kB
nld-deu         17226        278 kB        295 kB        858 kB
nld-eng         22748        380 kB        363 kB       1093 kB
nld-fra         16772        271 kB        246 kB        744 kB
por-deu          8296        126 kB        111 kB        313 kB
por-eng         10400        162 kB        121 kB        352 kB
sco-deu           259          3 kB          3 kB          7 kB
scr-eng           397          6 kB          4 kB         12 kB
slo-eng           829         11 kB          9 kB         22 kB
spa-eng          4504         67 kB         77 kB        209 kB
swa-eng          2680         33 kB         28 kB         92 kB
swe-eng          5222         71 kB         52 kB        150 kB
tur-deu           943         12 kB         11 kB         28 kB
tur-eng          1028         14 kB         11 kB         28 kB
english             0          0 kB          0 kB          0 kB
trans               0          0 kB          0 kB          0 kB
all                 0          0 kB          0 kB          0 kB
web1913        185399       3438 kB         11 MB         30 MB
world95           277          5 kB        936 kB       2796 kB
==== capabilities ====
auth:mime
==== END ====
