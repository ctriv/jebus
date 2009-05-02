package JebusBot::Console;
#
# $Id: Console.pm,v 1.3 2003/04/22 08:06:02 ctriv Exp $
#
# Stewie: Shake me like a British nanny! 
#

=head1 NAME

JebusBot::Bot - Probe Jebus's mind

=head1 SYNOPSIS

 use JebusBot::Constants qw(:console);
 
 $JebusBot::Console->put($msg, PLUG_INFO);
 
=head1 DESCRIPTION

This class implements Jebus's console.

=cut

use strict;
use warnings;

use JebusBot::Constants qw(:console);

use Term::ANSIColor;

my @types;

$types[NOTICE]    = {
	color => 'black',
	text  => 'NOTICE: ',
};

$types[INFO]      = {
	color => 'green',
	text  => 'INFO:   ',
};

$types[PLUG_INFO] = {
	color => 'blue',
	text  => 'PLUGIN: ',
};

$types[DEBUG]     = {
	color => 'red',
	text  => 'DEBUG:  ',
};

$types[IRC_IN]    = {
	color => 'yellow',
	text  => '  <<<   ',
};

$types[IRC_OUT]   = {
	color => 'cyan',
	text  => '  >>>   ',
};

$|++;

=head1 Methods

=head2 new()

Creates a JebusBot::Console object, pulling configuration from C<$JebusBot::Config>.

=cut

sub new {
	my ($class) = @_;
	
	my $self = {
		debug => $JebusBot::Config->get('debug'),
		on    => $JebusBot::Config->get('console'),
	};
	
	$self->{'debug'} and $self->{'on'}++;
	
	bless($self, $class);
	
	$self->put("Welcome to Jebus v$JebusBot::VERSION", NOTICE);
	
	return $self;
}

=head2 put($string, TYPE);

Prints C<$string> to the console under C<TYPE>.  C<TYPE> defaults to C<PLUG_INFO>.

=cut

sub put { 
	my ($self, $text, $type) = @_;
	
	return unless $self->{'on'};

	$type = PLUG_INFO unless defined $type;

	return unless $text and $types[$type];
		
	return if $type == DEBUG and !$self->{'debug'};
	
	$text =~ s/\s*$//;
	
	print colored("$types[$type]->{'text'}$text\n", $types[$type]->{'color'});
	
}


=head1 AUTHOR

Chris Reinhardt, <F<perl@triv.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 Chris Reinhardt

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

=head1 SEE ALSO

L<perl>, L<JebusBot>, 

=cut


1;
__END__
