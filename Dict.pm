# Net::Dict.pm
#
# Copyright (c) 1998 Dmitry Rubinstein <dimrub@wisdom.weizmann.ac.il>.
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

package Net::Dict;

use strict;
use IO::Socket;
use vars qw(@ISA $VERSION $debug);
use Net::Cmd;
use Carp;
use Net::Config;

$VERSION = $VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
my $CLIENT_INFO = "Dict.pm version $VERSION";

# $Header: /home/dimrub/wisdom/public_html/dict/Net/RCS/Dict.pm,v 1.3 1999/10/10 12:05:49 dimrub Exp $

#
# $Log: Dict.pm,v $
# Revision 1.3  1999/10/10 12:05:49  dimrub
# Inserted the $Revision$ keyword (a waste of version number)
#
# Revision 1.2  1999/10/04 11:51:02  dimrub
# Bug fix in 'sub define' (sent by Brian Kariger)
#
# Revision 1.1  1998/10/11 15:34:57  dimrub
# Initial revision
#
#


@ISA = qw(Net::Cmd IO::Socket::INET);

sub new
{
 my $self = shift;

 my $host = shift if @_ % 2;
 my %arg  = @_; 

 #??? If no host is specified, try one of the default servers.
 my $hosts = defined $host ? [ $host ] : $NetConfig{dict_hosts};
 my $obj;

 my $h;
 foreach $h (@{$hosts}) {
   $obj = $self->SUPER::new(PeerAddr => ($host = $h), 
			    PeerPort => $arg{Port} || 'dict(2628)',
			    Proto    => 'tcp',
			    Timeout  => defined $arg{Timeout} ? $arg{Timeout} : 120
			   ) and last;
  }

 return undef
	unless defined $obj;

 ${*$obj}{'net_dict_host'} = $host;

 $obj->autoflush(1);
 $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

 unless ($obj->response() == CMD_OK) {
   $obj->close();
   return undef;
  }

 ${*$obj}{'net_dict_banner'} = $obj->message;

 if ($obj->_SHOW_DB) {
	my($dbNum)= ($obj->message =~ /^\d{3} (\d+)/);
	my($name, $descr);
 	foreach (0..$dbNum-1) {
		($name, $descr) = (split /\s/, $obj->getline, 2);
		chomp $descr;
		${${*$obj}{'net_dict_dbs'}}{$name} = $descr;
	}
	# Is there a way to do it right? Reading the dot line and the
	# status line afterwards? Maybe I should use read_until_dot?
	$obj->getline();
	$obj->getline();
 }
 $obj->_CLIENT;

 # The default - search ALL dictionaries
 push @{${*$obj}{'net_dict_userdbs'}}, '*';

 $obj;
}

sub dbs {
	@_ == 1 or croak 'usage: $obj->dbs()';
	my $obj = shift;
	return %{${*$obj}{'net_dict_dbs'}};
}

sub setDicts {
	my $obj = shift;
	@{${*$obj}{'net_dict_userdbs'}} = @_;
}

sub serverInfo {
	@_ == 1 or croak 'usage: $obj->serverInfo()';
	my $obj = shift;

	return 0
		unless $obj->_SHOW_SERVER();
	my $info = join('', @{$obj->read_until_dot});
	$obj->getline();
	$info;
}

sub dbInfo {
	@_ == 2 or croak 'usage: $obj->dbInfo($dbname)';
	my $obj = shift;
	return 0 unless
		$obj->_SHOW_INFO(@_);
	@{$obj->read_until_dot()};
}

sub strats {
	@_ == 1 or croak 'usage: $obj->strats()';
	my $obj = shift;
	return 0
		unless $obj->_SHOW_STRAT();
	my(%strats, $name, $desc);
	foreach (@{$obj->read_until_dot()}) {
		($name, $desc) = (split /\s/, $_, 2);
		$strats{$name} = $desc;
	}
	$obj->getline();
	%strats;
}

sub define {
	my $obj = shift;
	my $word = shift;
	my @dbs = (@_ > 0) ? @_ : @{${*$obj}{'net_dict_userdbs'}};
	croak 'define some dictionaries by setDicts or supply as argument to define'
		unless @dbs;
	my($db, @defs);
	foreach $db (@dbs) {
		next
			unless $obj->_DEFINE($db, $word);

		my ($defNum) = ($obj->message =~ /^\d{3} (\d+) /);
		foreach (0..$defNum-1) {
			my ($d) = ($obj->getline =~ /^\d{3} ".*" (\w+) /);
			my ($def) = join '', @{$obj->read_until_dot};
			push @defs, [$d, $def];
		}
		$obj->getline();
	}
	\@defs;
}

sub match {
	@_ >= 3 or croak 'usage: $obj->match($word, $strat [, @dbs])';
	my $obj = shift;
	my $word = shift;
	my $strat = shift;
	my @dbs = (@_ > 0) ? @_ : @{${*$obj}{'net_dict_userdbs'}};
	croak 'define some dictionaries by setDicts or supply as argument to define'
		unless @dbs;
	my ($db, @matches);
	foreach $db (@dbs) {
		next unless $obj->_MATCH($db, $strat, $word);

		my ($db, $w);
		foreach (@{$obj->read_until_dot}) {
			($db, $w) = split /\s/, $_, 2;
			chomp $w;
			push @matches, [$db, $w];
		}
		$obj->getline();
	}
	\@matches; 
}

sub _DEFINE { shift->command('DEFINE', @_)->response() == CMD_INFO }
sub _MATCH { shift->command('MATCH', @_)->response() == CMD_INFO }
sub _SHOW_DB { shift->command('SHOW DB')->response() == CMD_INFO }
sub _SHOW_STRAT { shift->command('SHOW STRAT')->response() == CMD_INFO }
sub _SHOW_INFO { shift->command('SHOW INFO', @_)->response() == CMD_INFO }
sub _SHOW_SERVER { shift->command('SHOW SERVER')->response() == CMD_INFO }
sub _CLIENT { shift->command('CLIENT', $CLIENT_INFO)->response() == CMD_OK }
sub _STATUS { shift->command('STATUS')->response() == CMD_OK }
sub _HELP { shift->command('HELP')->response() == CMD_INFO }
sub _QUIT { shift->command('QUIT')->response() == CMD_OK }
sub _OPTION_MIME { shift->command('OPTION MIME')->response() == CMD_OK }
sub _AUTH { shift->command('AUTH', @_)->response() == CMD_OK }
sub _SASLAUTH { shift->command('SASLAUTH', @_)->response() == CMD_OK }
sub _SASLRESP { shift->command('SASLRESP', @_)->response() == CMD_OK }

sub quit
{
 my $me = shift;
 $me->_QUIT;
 $me->close;
}

sub DESTROY
{
 my $me = shift;

 if(defined fileno($me)) {
   $me->quit;
  }
}

sub response
{
 my $dict = shift;
 my $str = $dict->getline() || return undef;

 $dict->debug_print(0,$str)
   if ($dict->debug);

  my($code) = ($str =~ /^(\d+) /);

 ${*$dict}{'net_cmd_resp'} = [ $str ];
 ${*$dict}{'net_cmd_code'} = $code;

 substr($code,0,1);
}


1;

__END__

=head1 NAME

Net::Dict - Dict Client class

=head1 SYNOPSIS

	use Net::Dict;
    
	$dict = Net::Dict->new("some.host.name");
	$h = $dict->define("word");
	foreach $i (@{$h}) {
		($dict, $def) = @{$i};
		. . .
	}

=head1 DESCRIPTION

C<Net::Dict> is a class implementing a simple Dict client in Perl as
described in RFC2229.  It provides wrappers for a subset of the RFC2229
commands.

=head1 OVERVIEW

Quotation from RFC2229:

   The Dictionary Server Protocol (DICT) is a TCP transaction based
   query/response protocol that allows a client to access dictionary
   definitions from a set of natural language dictionary databases.

=head1 CONSTRUCTOR

=over 4

=item new (HOST [,OPTIONS])

This is the constructor for a new Net::Dict object. C<HOST> is the
name of the remote host on which a Dict server is running.

If the C<HOST> value is an empty string, the   default   behavior   is
to   try  dict.org, alt0.dict.org, alt1.dict.org, and alt2.dict.org,
in that order.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<ConfigFile> - The path to the configuration file (see dict(1) for
details on the format of the config. file). The config file entries
override the default definitions (e.g. server name and port), but are
overriden by an explicit definitions in the constructor.

B<HTML> - Give an output of 'match' and 'define' in HTML.

B<Port> - The port number to connect to on the remote machine for the
Dict connection (a default port number is 2628, according to RFC2229).

B<Timeout> - Set a timeout value (defaults to 120)

B<Debug> - debug level (see the debug method in L<Net::Cmd>)


=back

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, failure will be returned as I<undef> or an
empty list.

=over 4

=item auth (USER, SECRET) - perform an authentication protocol.

=item serverInfo - returns a string, containing the information about
the server.

=item dbs - returns hash, containing an ID of the dictionary as a
key and description as the value.

=item dbInfo($dbname) - returns a string, containing description of
the dictionary $dbname. 

=item setDicts (@dicts) - sets the set of dictionaries, that will be
searched during the successive define() calls. Defaults to '*'. No
existance checks are performed by this interface, so you'd better make
sure the dictionaries you specify are on the server (e.g. by calling
dbs()).

=item strats returns an array, containing an ID of a matching strategy
as a key and a verbose description as a value.

=item define($word [, @dbs]) - returns a reference to an array, whose
members are lists, consisting of two elements: the dictionary name and
the definition.  If no dictionaries are specified, those set by
setDicts() are used.

=item match($word, $strategy [, @dbs]) - same as define(), but a
matching using the specified strategies is performed. Return array of
lists, consisting of dictionary - match pairs.

=back

=head1 UNIMPLEMENTED

The following RFC2229 commands have not been implemented:

=over 4

=back

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.
It may be difficult for me to reproduce the problem as almost every setup
is different.

A small script which yields the problem will probably be of help. It would
also be useful if this script was run with the extra options C<Debug => 1>
passed to the constructor, and the output sent with the bug report. If you
cannot include a small script then please include a Debug trace from a
run of your program which does yield the problem.

=head1 AUTHOR

Dmitry Rubinstein <dimrub@wisdom.weizmann.ac.il>
Net::FTP and Net::SMTP modules were used as a pattern and a model for
imitation.

=head1 SEE ALSO

L<Net::Netrc>
L<Net::Cmd>

dict(1), dictd(8), RFC 2229
http://www.cis.ohio-state.edu/htbin/rfc/rfc2229.html
http://www.dict.org/

=head1 CREDITS

=head1 COPYRIGHT

Copyright (c) 1998 Dmitry Rubinstein. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
