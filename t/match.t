#!./perl
#
# match.t - Net::Dict testsuite for match() method
#

use Net::Dict;
use lib qw(. ./blib/lib ../blib/lib ./t);
require 'test_host.cfg';
use Env qw($VERBOSE);

$^W = 1;

my $WARNING;
my %TESTDATA;
my $defref;
my $section;
my $string;
my $dbinfo;
my %strathash;

if (defined $VERBOSE && $VERBOSE==1)
{
    print STDERR "\nVERBOSE ON\n";
}

print "1..15\n";

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
# connect to server
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($HOST, Port => $PORT); };
if (!$@ && defined $dict)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
}

#-----------------------------------------------------------------------
# call match() with no arguments - should die
#-----------------------------------------------------------------------
eval { $defref = $dict->match(); };
if ($@ && $@ =~ /takes at least two arguments/)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}

#-----------------------------------------------------------------------
# call match() with one arguments - should die
#-----------------------------------------------------------------------
eval { $defref = $dict->match('banana'); };
if ($@ && $@ =~ /takes at least two arguments/)
{
    print "ok 4\n";
}
else
{
    print "not ok 4\n";
}

#-----------------------------------------------------------------------
# call match() with two arguments, but word is undef
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->match(undef, '*'); };
if (!$@
    && !defined($defref)
    && $WARNING =~ /empty pattern passed to match/)
{
    print "ok 5\n";
}
else
{
    print "not ok 5\n";
}

#-----------------------------------------------------------------------
# call match() with two arguments, but word is undef
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->match('', '*'); };
if (!$@
    && !defined($defref)
    && $WARNING =~ /empty pattern passed to match/)
{
    print "ok 6\n";
}
else
{
    print "not ok 6\n";
}

#-----------------------------------------------------------------------
# get a list of supported strategies, render as string and compare
#-----------------------------------------------------------------------
$string = '';
eval { %strathash = $dict->strategies(); };
if (!$@
    && %strathash
    && do {
        foreach my $s (sort keys %strathash)
        {
            $string .= $s.':'.$strathash{$s}."\n";
        }
        1;
    }
    && $string eq $TESTDATA{'strats'})
{
    print "ok 7\n";
}
else
{
    print STDERR "\nTEST 7\nexpected \"", $TESTDATA{'strats'},
                 "\", got \n\"$string\"\n";
    print "not ok 7\n";
}

#-----------------------------------------------------------------------
# same as previous test, but using obsolete method name
#-----------------------------------------------------------------------
$string = '';
eval { %strathash = $dict->strats(); };
if (!$@
    && %strathash
    && do {
        foreach my $s (sort keys %strathash)
        {
            $string .= $s.':'.$strathash{$s}."\n";
        }
        1;
    }
    && $string eq $TESTDATA{'strats'})
{
    print "ok 8\n";
}
else
{
    print STDERR "\nTEST 8\nexpected \"", $TESTDATA{'strats'},
                 "\", got \n\"$string\"\n";
    print "not ok 8\n";
}

#-----------------------------------------------------------------------
# A list of words which start with "blue screen" - ie contains
# a space.
#-----------------------------------------------------------------------
eval { $defref = $dict->match('blue screen', 'prefix', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'*-prefix-blue_screen'})
{
    print "ok 9\n";
}
else
{
    print "not ok 9\n";
}

#-----------------------------------------------------------------------
# A list of words which start with "blue " in the jargon dictionary.
# We've previously specified a default dictionary of foldoc,
# but we shouldn't get anything from that.
#-----------------------------------------------------------------------
$dict->setDicts('foldoc');
eval { $defref = $dict->match('blue ', 'prefix', 'jargon'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'jargon-prefix-blue_'})
{
    print "ok 10\n";
}
else
{
    print STDERR "\nTEST 10\nexpected \"", $TESTDATA{'jargon-prefix-blue_'},
                 "\", got \n\"$string\"\n";
    print "not ok 10\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Now we do the same match, but without specifying a dictionary,
# so it should fall back on the previously specified foldoc
#-----------------------------------------------------------------------
$dict->setDicts('foldoc');
eval { $defref = $dict->match('blue ', 'prefix'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'foldoc-prefix-blue_'})
{
    print "ok 11\n";
}
else
{
    print "not ok 11\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Look for words with apostrophe in them, in a specific dictionary
#-----------------------------------------------------------------------
eval { $defref = $dict->match("'", 're', 'world95'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{"world95-re-'"})
{
    print "ok 12\n";
}
else
{
    print "not ok 12\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# look for all words in all dictionaries ending in "standard"
#-----------------------------------------------------------------------
eval { $defref = $dict->match("standard", 'suffix', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'*-suffix-standard'})
{
    print "ok 13\n";
}
else
{
    print STDERR "\nTEST 13\nexpected \"", $TESTDATA{'*-suffix-standard'},
                 "\", got \n\"$string\"\n";
    print "not ok 13\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Using regular expressions to find all entries in a dictionary
# of a given length
#-----------------------------------------------------------------------
eval { $defref = $dict->match('^...................................$',
                              're', 'web1913'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'web1913-re-dotmatch'})
{
    print "ok 14\n";
}
else
{
    print "not ok 14\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Look for words which have a Levenshtein distance one
# from "know"
#-----------------------------------------------------------------------
eval { $defref = $dict->match('know', 'lev', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'*-lev-know'})
{
    print "ok 15\n";
}
else
{
    print STDERR "\nTEST 15\nexpected \"", $TESTDATA{'*-lev-know'},
                 "\", got \n\"$string\"\n";
    print "not ok 15\n";
}


exit 0;

#=======================================================================
#
# _format_matches()
#
# takes a reference to a list which is assumed to be the result
# from a match() - each entry in the list is a reference to
# a 2-element list: [DICTIONARY, WORD]
#
# We return a string which has one line per entry:
#        DICTIONARY:WORD
# sorted on the whole line (ie by dictionary, then by word)
#
#=======================================================================
sub _format_matches
{
    my $mref  = shift;

    my $string = '';


    foreach my $entry (sort { lc($a->[0].$a->[1]) cmp lc($b->[0].$b->[1]) } @$mref)
    {
        $string .= $entry->[0].':'.$entry->[1]."\n";
    }

    return $string;
}

__DATA__
==== strats ====
exact:Match words exactly
lev:Match words within Levenshtein distance one
prefix:Match prefixes
re:POSIX 1003.2 (modern) regular expressions
regexp:Old (basic) regular expressions
soundex:Match using SOUNDEX algorithm
substring:Match substring occurring anywhere in word
suffix:Match suffixes
==== *-exact-blue ====
easton:Blue
foldoc:Blue
gazetteer:Blue
web1913:Blue
web1913:blue
wn:blue
==== *-prefix-blue_screen ====
foldoc:Blue Screen of Death
foldoc:Blue Screen of Life
jargon:Blue Screen of Death
==== jargon-prefix-blue_ ====
jargon:Blue Book
jargon:blue box
jargon:Blue Glue
jargon:blue goo
jargon:Blue Screen of Death
jargon:blue wire
==== foldoc-prefix-blue_ ====
foldoc:Blue Book
foldoc:Blue Box
foldoc:Blue Glue
foldoc:Blue Screen of Death
foldoc:Blue Screen of Life
foldoc:Blue Sky Software
foldoc:blue wire
==== world95-re-' ====
world95:Cote D'ivoire
==== *-suffix-standard ====
foldoc:A Tools Integration Standard
foldoc:Advanced Encryption Standard
foldoc:American National Standard
foldoc:Binary Compatibility Standard
foldoc:Data Encryption Standard
foldoc:de facto standard
foldoc:Digital Signature Standard
foldoc:display standard
foldoc:IEEE Floating Point Standard
foldoc:International Standard
foldoc:Object Compatibility Standard
foldoc:Recommended Standard
foldoc:standard
gazetteer:Standard
jargon:ANSI standard
web1913:Double standard
web1913:standard
web1913:Standard
wn:double standard
wn:gold standard
wn:monetary standard
wn:nonstandard
wn:silver standard
wn:standard
wn:substandard
==== *-soundex-foobar ====
easton:Fever
foldoc:feeper
foldoc:foobar
foldoc:FUBAR
gazetteer:Faber
gazetteer:Fibre
jargon:feeper
jargon:foobar
jargon:FUBAR
vera:FOOBAR
vera:FUBAR
web1913:Favor
web1913:Feaberry
web1913:Feoffer
web1913:Feofor
web1913:fever
web1913:Fever
web1913:Fevery
web1913:Fibber
web1913:Fiber
web1913:fibre
web1913:Fibre
web1913:Fifer
web1913:Foppery
web1913:Fubbery
wn:favor
wn:favour
wn:fever
wn:fibber
wn:fiber
wn:fibre
wn:fiver
==== web1913-re-dotmatch ====
web1913:a Minors Gray Friars or Franciscans
web1913:All is grist that comes to his mill
web1913:Amaryllis or Sprekelia formosissima
web1913:Arithmetical complement of a number
web1913:Carcharodon carcharias or Rondeleti
web1913:Commission of general gaol delivery
web1913:Hirneola Auricula-Judae or Auricula
web1913:Incoordination of muscular movement
web1913:Malpighian corpuscles of the spleen
web1913:orthosilicic or normal silicic acid
web1913:Solen or Ensatella ensis  Americana
web1913:Sphinx or Macrosila quinquemaculata
web1913:sulphovinic or ethyl sulphuric acid
web1913:To change a horse or To change hand
web1913:to one's people or to one's fathers
web1913:To take the wind out of one's sails
web1913:Vespertilio or Noctulina altivolans
web1913:Vickers-Maxim automatic machine gun
web1913:Young Women's Christian Association
==== *-lev-know ====
easton:Knop
easton:Snow
gazetteer:Knox
gazetteer:Snow
web1913:Enow
web1913:Gnow
web1913:Knaw
web1913:Knew
web1913:Knob
web1913:Knop
web1913:Knor
web1913:Knot
web1913:Know
web1913:Known
web1913:Now
web1913:Snow
web1913:Ynow
wn:knob
wn:knot
wn:know
wn:known
wn:now
wn:snow
==== END ====
