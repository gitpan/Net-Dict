#
# Makefile.PL for Net-Dict
#
# $Id: Makefile.PL,v 1.2 2001/02/22 18:00:39 neilb Exp $
#

use ExtUtils::MakeMaker;


&WriteMakefile(
                NAME         => 'Net::Dict',
                DISTNAME     => 'Net-Dict',
		VERSION_FROM => 'lib/Net/Dict.pm',
                PREREQ_PM    => {
                                 'IO::Socket'	=> 0,
                                 'Net::Cmd'	=> 0,
                                 'Carp'		=> 0,
                                 'Net::Config'	=> 0,
                                },
                dist         => {COMPRESS => 'gzip', SUFFIX => 'gz'},
              );

