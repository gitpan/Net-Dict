#
# Net::Dict.pm
#
# Copyright (C) 2001 Neil Bowers <neilb@cre.canon.co.uk>
# Copyright (c) 1998 Dmitry Rubinstein <dimrub@wisdom.weizmann.ac.il>.
#
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Dict.pm,v 1.7 2001/03/04 16:53:47 neilb Exp $
#

package Net::Dict;

use strict;
use IO::Socket;
use vars qw(@ISA $VERSION $debug);
use Net::Cmd;
use Carp;
use Net::Config;

$VERSION = $VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);
my $CLIENT_INFO = "Dict.pm version $VERSION";

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
			    PeerPort => $arg{Port} || 2628,
			    Proto    => 'tcp',
			    Timeout  => defined $arg{Timeout} ? $arg{Timeout} : 120
			   ) and last;
    }

    return undef
	unless defined $obj;

    $CLIENT_INFO = $arg{Client} if defined $arg{Client};

    ${*$obj}{'net_dict_host'} = $host;

    $obj->autoflush(1);
    $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

    unless ($obj->response() == CMD_OK) {
        $obj->close();
        return undef;
    }

    ${*$obj}{'net_dict_banner'} = $obj->message;

    if ($obj->_SHOW_DB)
    {
	my($dbNum)= ($obj->message =~ /^\d{3} (\d+)/);
	my($name, $descr);
 	foreach (0..$dbNum-1) {
            ($name, $descr) = (split /\s/, $obj->getline, 2);
            chomp $descr;
            ${${*$obj}{'net_dict_dbs'}}{$name} = _unquote($descr);
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

sub dbs
{
    @_ == 1 or croak 'usage: $obj->dbs()';
    my $obj = shift;
    return %{${*$obj}{'net_dict_dbs'}};
}

sub setDicts
{
    my $obj = shift;
    @{${*$obj}{'net_dict_userdbs'}} = @_;
}

sub serverInfo
{
    @_ == 1 or croak 'usage: $obj->serverInfo()';
    my $obj = shift;

    return 0
        unless $obj->_SHOW_SERVER();
    my $info = join('', @{$obj->read_until_dot});
    $obj->getline();
    $info;
}

sub dbInfo
{
    @_ == 2 or croak 'usage: $obj->dbInfo($dbname)';
    my $obj = shift;
    return 0 unless
        $obj->_SHOW_INFO(@_);
    @{$obj->read_until_dot()};
}

sub dbTitle
{
    @_ == 2 or croak 'dbTitle() method expects one argument - DB name';
    my $self   = shift;
    my $dbname = shift;

    return ${${*$self}{'net_dict_dbs'}}{$dbname};
}

sub strats
{
    @_ == 1 or croak 'usage: $obj->strats()';
    my $obj = shift;
    return 0
        unless $obj->_SHOW_STRAT();
    my(%strats, $name, $desc);
    foreach (@{$obj->read_until_dot()})
    {
        ($name, $desc) = (split /\s/, $_, 2);
        chomp $desc;
        $strats{$name} = _unquote($desc);
    }
    $obj->getline();
    %strats;
}

sub define
{
    my $obj = shift;
    my $word = shift;
    my @dbs = (@_ > 0) ? @_ : @{${*$obj}{'net_dict_userdbs'}};
    croak 'define some dictionaries by setDicts or supply as argument to define'
        unless @dbs;
    my($db, @defs);
    foreach $db (@dbs)
    {
        next
            unless $obj->_DEFINE($db, $word);

        my ($defNum) = ($obj->message =~ /^\d{3} (\d+) /);
        foreach (0..$defNum-1)
        {
            my ($d) = ($obj->getline =~ /^\d{3} ".*" (\w+) /);
            my ($def) = join '', @{$obj->read_until_dot};
            push @defs, [$d, $def];
        }
        $obj->getline();
    }
    \@defs;
}

sub match
{
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
            push @matches, [$db, _unquote($w)];
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
    my $self = shift;

    $self->_QUIT;
    $self->close;
}

sub DESTROY
{
    my $self = shift;

    if (defined fileno($self)) {
        $self->quit;
    }
}

sub response
{
    my $self = shift;
    my $str = $self->getline() || return undef;


    if ($self->debug)
    {
        $self->debug_print(0,$str);
    }

    my($code) = ($str =~ /^(\d+) /);

    ${*$self}{'net_cmd_resp'} = [ $str ];
    ${*$self}{'net_cmd_code'} = $code;

    substr($code,0,1);
}

#=======================================================================
#
# _unquote
#
# Private function used to remove quotation marks from around
# a string.
#
#=======================================================================
sub _unquote
{
    my $string = shift;


    if ($string =~ /^"/)
    {
        $string =~ s/^"//;
        $string =~ s/"$//;
    }
    return $string;
}

1;

__END__

=head1 NAME

Net::Dict - client API for accessing dictionary servers (RFC 2229)

=head1 SYNOPSIS

    use Net::Dict;
    
    $dict = Net::Dict->new("some.host.name");
    $h = $dict->define("word");
    foreach $i (@{$h}) {
        ($db, $def) = @{$i};
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

    $dict = Net::Dict->new (HOST [,OPTIONS]);

This is the constructor for a new Net::Dict object. C<HOST> is the
name of the remote host on which a Dict server is running.

If the C<HOST> value is an empty string, the default behavior is
to try dict.org, alt0.dict.org, alt1.dict.org, and alt2.dict.org,
in that order.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

=over 4

=item B<ConfigFile>

The path to the configuration file (see dict(1) for
details on the format of the config. file). The config file entries
override the default definitions (e.g. server name and port), but are
overriden by an explicit definitions in the constructor.

=item B<HTML>

Give an output of 'match' and 'define' in HTML.

=item B<Port>

The port number to connect to on the remote machine for the
Dict connection (a default port number is 2628, according to RFC2229).

=item B<Client>

The string to send as the CLIENT identifier.
If not set, then a default identifier for Net::Dict is sent.

=item B<Timeout>

Set a timeout value (defaults to 120)

=item B<Debug>

debug level (see the debug method in L<Net::Cmd>)

=back

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, failure will be returned as I<undef> or an
empty list.

=over 4

=item serverInfo()

returns a string, containing the information about the server.

=item dbs()

returns a hash, containing an ID of the dictionary as a
key and description as the value.

=item dbInfo($dbname)

returns a string, containing description of
the dictionary $dbname. 

=item setDicts(@dicts)

sets the set of dictionaries, that will be
searched during the successive define() calls. Defaults to '*'. No
existance checks are performed by this interface, so you'd better make
sure the dictionaries you specify are on the server (e.g. by calling
dbs()).

=item strats()

returns an array, containing an ID of a matching strategy
as a key and a verbose description as a value.

=item define($word [, @dbs])

returns a reference to an array, whose
members are lists, consisting of two elements: the dictionary name and
the definition.  If no dictionaries are specified, those set by
setDicts() are used.

=item match($word, $strategy [, @dbs])

same as define(), but a
matching using the specified strategies is performed. Return array of
lists, consisting of dictionary - match pairs.

=item dbTitle($dbname)

Returns the title string for the specified dictionary.
This is the same string returned by the C<dbs()> method
for all databases.

=back

=head1 UNIMPLEMENTED

The following RFC2229 commands have not been implemented:

=over 4

=item authentication

The authentication protocol isn't currently implemented.

=back

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.
It may be difficult for me to reproduce the problem as almost every setup
is different.

A small script which yields the problem will probably be of help. It would
also be useful if this script was run with the extra options C<Debug =E<gt> 1>
passed to the constructor, and the output sent with the bug report. If you
cannot include a small script then please include a Debug trace from a
run of your program which does yield the problem.

=head1 EXAMPLES

The B<examples> directory of the Net-Dict distribution
includes simple.pl, which illustrates basic use of the module.

=head1 AUTHOR

Net::Dict was written by
Dmitry Rubinstein E<lt>dimrub@wisdom.weizmann.ac.ilE<gt>,
using Net::FTP and Net::SMTP as a pattern and a model for imitation.

The module is now maintained by
Neil Bowers E<lt>neilb@cre.canon.co.ukE<gt>

=head1 SEE ALSO

L<Net::Netrc>
L<Net::Cmd>

dict(1), dictd(8), RFC 2229
http://www.cis.ohio-state.edu/htbin/rfc/rfc2229.html
http://www.dict.org/

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe, Ltd.

Copyright (c) 1998 Dmitry Rubinstein. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

