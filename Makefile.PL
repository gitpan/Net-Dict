#
# Makefile.PL for Net-Dict
#
# $Id: Makefile.PL,v 1.4 2001/02/28 20:00:39 neilb Exp $
#

use ExtUtils::MakeMaker;


&WriteMakefile(
                NAME		=> 'Net::Dict',
                DISTNAME	=> 'Net-Dict',
		VERSION_FROM	=> 'lib/Net/Dict.pm',
                PREREQ_PM	=> {
                                 'IO::Socket'	=> 0,
                                 'Net::Cmd'	=> 0,
                                 'Carp'		=> 0,
                                 'Net::Config'	=> 0,
                                },
		EXE_FILES	=> [qw(dict)],
		AUTHOR		=> 'Neil Bowers <neilb@cre.canon.co.uk>',
		ABSTRACT_FROM	=> 'lib/Net/Dict.pm',
                dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},
              );

