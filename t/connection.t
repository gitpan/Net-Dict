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

print "1..10\n";

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
    print STDERR "GOT STRING: \"$serverinfo\"\n";
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

exit 0;

__DATA__
==== serverinfo ====

Database      Headwords         Index          Data  Uncompressed
elements            130          2 kB         14 kB         45 kB
web1913          185399       3438 kB         11 MB         30 MB
wn               121967       2427 kB       7142 kB         21 MB
gazetteer         52994       1087 kB       1754 kB       8351 kB
jargon             2371         42 kB        606 kB       1368 kB
foldoc            13258        255 kB       1978 kB       4850 kB
easton             3968         64 kB       1077 kB       2648 kB
hitchcock          2619         34 kB         33 kB         85 kB
devils              997         15 kB        161 kB        377 kB
world95             277          5 kB        936 kB       2796 kB
vera               8448         95 kB        144 kB        505 kB
==== END ====
