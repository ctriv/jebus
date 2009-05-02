package JebusBot::Plugin::Join;
#
# $Id: Join.pm,v 1.9 2003/05/19 06:20:12 ctriv Exp $
#
# Stewie: "Hello mother, care to partake in one of your oh-so-exhilarating 
#          games of Peek-a-boo?" 
#

=head1 NAME

JebusBot::Plugin::Join

=head1 PREREQUISITES

None

=head1 PARAMETERS

=head2 DefaultChannels

	<Plugin Seen>
		DefaultChannels <channel> [channel2 channel3 ...]
	</Plugin>

The channels that Jebus should join at startup.

=head1 PUBLIC INTERFACE

	<botname>, join <channel>
	<botname>, part <channel>

=head1 DESCRIPTION

Manages the joining and parting of channels.

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

use JebusBot::Constants qw(:plugin);

use base 'JebusBot::Plugin';

use strict;
use warnings;

sub new {
	my ($class) = @_;
	
	my $self = $class->SUPER::new;
	
	$self->{'channels'} = [ split(m/\s+/, $self->config->{'defaultchannels'}) ];
		
	return $self;	
}


sub irc_001 {
	my ($self) = @_;
		
	foreach my $chan (@{$self->{'channels'}}) {
		$JebusBot::Console->put("Join: joining $chan");
		$self->join($chan);
	}
	
	return NEXT;
}

sub irc_public {
	my ($self, $event) = @_;
		
	if ($event->addressed and $event->msg =~ m/^join\s*(#\w+)/i) {
		$JebusBot::Console->put("Join: joining $1");
		$self->join($1);
		return DONE;
	}
	
	if ($event->addressed and $event->msg =~ m/^part\s*(#\w+)/i) {
		$JebusBot::Console->put("Join: parting $1");
		$self->part($1);
		return DONE;
	}
	
	return NEXT;
}

  
1; 
