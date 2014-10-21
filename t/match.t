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
    print STDERR "\nTEST 9\nexpected \"", $TESTDATA{'*-prefix-blue_screen'},
                 "\", got \n\"$string\"\n";
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
    print STDERR "\nTEST 11\nexpected \"", $TESTDATA{'foldoc-prefix-blue_'},
                 "\", got \n\"$string\"\n";
    print "not ok 11\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Look for words with apostrophe in them, in a specific dictionary
#-----------------------------------------------------------------------
eval { $defref = $dict->match("d'i", 're', 'world95'); };
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
eval { $defref = $dict->match('^a....................$',
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
    print STDERR "\nTEST 14\nexpected \"", $TESTDATA{'web1913-re-dotmatch'},
                 "\", got \n\"$string\"\n";
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
exact:Match headwords exactly
lev:Match headwords within Levenshtein distance one
prefix:Match prefixes
re:POSIX 1003.2 (modern) regular expressions
regexp:Old (basic) regular expressions
soundex:Match using SOUNDEX algorithm
substring:Match substring occurring anywhere in a headword
suffix:Match suffixes
word:Match separate words within headwords
==== *-exact-blue ====
easton:Blue
foldoc:Blue
gazetteer:Blue
web1913:Blue
web1913:blue
wn:blue
==== *-prefix-blue_screen ====
foldoc:blue screen of death
foldoc:blue screen of life
jargon:Blue Screen of Death
==== jargon-prefix-blue_ ====
jargon:Blue Book
jargon:blue box
jargon:Blue Glue
jargon:blue goo
jargon:Blue Screen of Death
jargon:blue wire
==== foldoc-prefix-blue_ ====
foldoc:blue book
foldoc:blue box
foldoc:blue dot syndrome
foldoc:blue glue
foldoc:blue screen of death
foldoc:blue screen of life
foldoc:blue sky software
foldoc:blue wire
==== world95-re-' ====
world95:Cote D'ivoire
==== *-suffix-standard ====
bouvier:STANDARD
foldoc:a tools integration standard
foldoc:advanced encryption standard
foldoc:american national standard
foldoc:binary compatibility standard
foldoc:data encryption standard
foldoc:de facto standard
foldoc:digital signature standard
foldoc:display standard
foldoc:filesystem hierarchy standard
foldoc:ieee floating point standard
foldoc:international standard
foldoc:object compatibility standard
foldoc:recommended standard
foldoc:standard
gaz-place:Standard
gazetteer:Standard
gcide:deficient inferior substandard
gcide:Double standard
gcide:double standard
gcide:non-standard
gcide:nonstandard
gcide:standard
gcide:Standard
jargon:ANSI standard
moby-thes:standard
wn:accounting standard
wn:double standard
wn:gold standard
wn:monetary standard
wn:nonstandard
wn:silver standard
wn:standard
wn:substandard
==== web1913-re-dotmatch ====
web1913:a lie or an assertion
web1913:Abraxas grossulariata
web1913:Acanthopis antarctica
web1913:Accentor rubeculoides
web1913:Acceptance of persons
web1913:acid sodium carbonate
web1913:Adhesive inflammation
web1913:Adventitious membrane
web1913:AEgeria polistiformis
web1913:AEgopodium podagraria
web1913:AEgopodium Podagraria
web1913:African calabash tree
web1913:After one's own heart
web1913:Agapanthus umbellatus
web1913:Agrostis Spica-ventis
web1913:also its milky juice 
web1913:Altitude of a pyramid
web1913:Ambloplites rupestris
web1913:Ambrosia artemisiaege
web1913:Ammodytes lanceolatus
web1913:Ammophila arundinacea
web1913:Amphicerus bicaudatus
web1913:Amphioxus lanceolatus
web1913:Anacampsis sarcitella
web1913:Anallagmatic surfaces
web1913:Anarhynchus frontalis
web1913:Andropogon Halepensis
web1913:Anemopsis Californica
web1913:Angelica archangelica
web1913:Anisopteryx pometaria
web1913:Anseranas semipalmata
web1913:Anthistiria australis
web1913:Anthoxanthum odoratum
web1913:Anthriscus cerefolium
web1913:Anthyllis Barba-Jovis
web1913:Antilocapra Americana
web1913:Antrostomus vociferus
web1913:Aphenogaster structor
web1913:Aphrophora interrupta
web1913:Aplodinotus grunniens
web1913:Arbitrary coefficient
web1913:Argillaceous iron ore
web1913:As good as one's word
web1913:Asclepias Curassavica
web1913:Asparagus officinalis
web1913:Aspidosperma excelsum
web1913:Atherosperma moschata
==== *-lev-know ====
easton:Knop
easton:Snow
gaz-county:Knox
gaz-place:Knox
gazetteer:Knox
gazetteer:Snow
gcide:Aknow
gcide:Enow
gcide:Gnow
gcide:Knaw
gcide:Knew
gcide:Knob
gcide:Knop
gcide:Knor
gcide:knot
gcide:Known
gcide:Now
gcide:Snow
gcide:Ynow
moby-thes:knob
moby-thes:knot
moby-thes:now
moby-thes:snow
vera:now
wn:knew
wn:knob
wn:knot
wn:known
wn:Knox
wn:now
wn:snow
==== END ====
