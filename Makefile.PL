#
# Makefile.PL for Net-Dict
#
# $Id: Makefile.PL,v 1.5 2001/03/04 16:54:15 neilb Exp $
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
		EXE_FILES	=> [qw(dict tkdict)],
		AUTHOR		=> 'Neil Bowers <neilb@cre.canon.co.uk>',
		ABSTRACT_FROM	=> 'lib/Net/Dict.pm',
                dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},
              );

