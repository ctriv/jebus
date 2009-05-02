package JebusBot::Event;
#
# $Id: Event.pm,v 1.17 2003/05/19 22:21:51 ctriv Exp $ 
#
#
# Stewie: What are the stakes of this wager? 
# Brian:  Why don't you shut up for about a week? 
# Stewie: Very well.  And if I win? 
# Brian:  I wasn't betting.  Why don't you just shut up for about a week. 
#

use strict;
use warnings;

use JebusBot::Constants qw(:console);
use JebusBot::Filter ();

=head1 NAME

JebusBot::Event - News from the outside word... at last.

=head1 DESCRIPTION

Event objects are handed to a plugin's methods by the jebus framework.  These
event objects contain information about the event that just happened.  Each event
type in jebus is passed an event object of a certain subclass of JebusBot::Event.

Plugin authors are welcome to use the event object as a hashref scratch pad.  This
can be useful for storing information needed for the duration of the request.
Key names starting with C<_> are reserved for internal use.

See the documentation below for details.

=head1 METHODS

All event classes defind the following methods, though they may not return anything
meaningful.

=head2 $event->msg

Returns the message for this event.

=head2 $event->addressed

Returns boolean, true if this message appears to be addressing Jebus.

=head2 $event->raw_msg

Returns the message for this event without any normalization or filtering.

=head2 $event->channel

Returns the channel that this event happened in.

=head2 $event->nick

Returns the nick of the person that sent C<<$event->msg>>.

=head2 $event->username

Returns the username of the person that sent C<<$event->msg>>.

=head2 $event->hostname

Returns the hostname of the person that sent C<<$event->msg>>.

=head2 $event->where

Returns an arrayref of all the channels that this event happened in.

=cut

my @methods = qw(
	msg
	addressed 
	raw_msg
	channel
	nick
	username
	hostname
	where
);

sub _create_method {
	my ($class, $method) = @_;
	
	no strict q/refs/;
	
	*{"${class}::$method"} = sub {
		my ($self, $arg) = @_;
		
		if (defined $arg) {
			$self->{"_$method"} = $arg;
		}
		
		return $self->{"_$method"};
	}
}

for (@methods) {
	__PACKAGE__->_create_method($_);
}

sub new   { bless({}, $_[0])             }
sub clone { bless({%{$_[0]}}, ref $_[0]) }

#
# split the nick!user@host up and store it in the event.
#
sub _parse_nickmask {
	my ($self, $mask) = @_;
	
	return unless $mask;
	
	if ($mask =~ m/!/) {
		my $hostmask;	
		($self->{'_nick'}, $hostmask) = split(m/!/, $mask, 2);
		
		($self->{'_username'}, $self->{'_hostname'}) = split(m/\@/, $hostmask);
	} else {
		if ($mask =~ m/\./) {
			$self->{'_hostname'} = $mask;
		} else {
			$self->{'_nick'} = $mask;
		}
	}
}


#
# Figure out if we've beeing addressed.
#

my $address_regex;

sub _parse_addressed {
	my ($self) = @_;
	
	unless ($self->{'_msg'}) {
		$self->{'_addressed'} = 0;
		return;
	}
		
	unless (defined $self->{'_addressed'}) {
		unless ($address_regex) {
			my $names = CORE::join('|', JebusBot::bot_names());
			
			$address_regex = qr/^(?:$names)\s*(?:[:;,-]|\.+)\s*/i;
			
			$JebusBot::Console->put("Addressing Regexp: $address_regex", DEBUG);
		}
		
		
				
		$self->{'_raw_msg'} = $self->{'_msg'};
		
		$self->{'_msg'} =~ s/\s+$//;
		
		if ($self->{'_msg'} =~ s/$address_regex//) {
			$self->{'_addressed'} = 1;
		} else {
			$self->{'_addressed'} = 0;
		}	
	}
}

=head1 Filtering

Filters can be applied to the event object, these mainly modify the message
of the event, but they can modify any part of the message object.

=head2 $event->filter($filter_name)

Loads C<JebusBot::Filter::$filter_name> and applies it to the an event object.
This object will be returned by this method, while the invoking object is
left unchanged. This method will die if the given filter does not exist, so 
use C<eval {}> where appropriate.

For example:

	my $crack;
	eval { $crack = $event->filter('Crack') };
	
	die "Got busted for buying crack!" if $@;

Returns a new event object with the modified information:

	my $event = $raw_event->filter('Infobotish');

=cut

sub filter {
	my ($self, $filter) = @_;
	
	return unless $filter;
	
	my $class = JebusBot::Filter->load_filter($filter);	
	
	$class->apply_filter($self);
}	
	

=head1 Event Classes

Each type of event has it's own subclass which may contain extra methods
allowing access to additional state attributes.  This document merely
describes the methods of each event subclass. See the Event listings in
L<JebusBot::Plugin> for more information.

=head2 JebusBot::Event::irc_001

This class does not use any methods.

=cut

package JebusBot::Event::irc_001;

use strict;
use warnings;
use base 'JebusBot::Event';



=head2 JebusBot::Event::irc_ping

This class does not use any methods.

=cut

package JebusBot::Event::irc_ping;

use strict;
use warnings;
use base 'JebusBot::Event';



=head2 JebusBot::Event::irc_error

This class uses the following methods:

=over 2 

=item $event->error

The ERROR message from the server.

=back

=cut

package JebusBot::Event::irc_error;

use strict;
use warnings;
use base 'JebusBot::Event';

__PACKAGE__->_create_method('error');

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->{'_error'} = $_[JebusBot::Constants::ARG0];

	return $self;
}



=head2 JebusBot::Event::irc_join

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=back

=cut

package JebusBot::Event::irc_join;

use strict;
use warnings;
use base 'JebusBot::Event';

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->_parse_nickmask($_[JebusBot::Constants::ARG0]);
	
	$self->{'_channel'} = $_[JebusBot::Constants::ARG1];
	
	return $self;
}



=head2 JebusBot::Event::irc_invite

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=back

=cut

package JebusBot::Event::irc_invite;

use strict;
use warnings;
use base 'JebusBot::Event::irc_join';



=head2 JebusBot::Event::irc_part

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=back

=cut

package JebusBot::Event::irc_part;

use strict;
use warnings;
use base 'JebusBot::Event::irc_join';



=head2 JebusBot::Event::irc_quit

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=back

=cut

package JebusBot::Event::irc_quit;

use strict;
use warnings;
use base 'JebusBot::Event::irc_join';



=head2 JebusBot::Event::irc_kick

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=item $event->msg

=item $event->addressed

=item $event->luser

The nick of the user that was kicked off the channel.

=back

=cut

package JebusBot::Event::irc_kick;

use strict;
use warnings;
use base 'JebusBot::Event';

__PACKAGE__->_create_method('luser');

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->_parse_nickmask($_[JebusBot::Constants::ARG0]);
	
	$self->{'_channel'} = $_[JebusBot::Constants::ARG1];
	$self->{'_luser'}   = $_[JebusBot::Constants::ARG2];
	$self->{'_msg'}     = $_[JebusBot::Constants::ARG3];
	
	$self->_parse_addressed;
	
	return $self;
}
	



=head2 JebusBot::Event::irc_mode

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->thing

The 'thing' that was affected by the mode change.

=item $event->string

The mode string (i.e., "+o-b").

=item $event->ops

An arrayref of the operands to the mode string.

=back

=cut

package JebusBot::Event::irc_mode;

use strict;
use warnings;
use base 'JebusBot::Event';

__PACKAGE__->_create_method($_) for qw(thing string ops);

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->_parse_nickmask($_[JebusBot::Constants::ARG0]);
	
	$self->{'_thing'}   = $_[JebusBot::Constants::ARG1];
	$self->{'_string'}  = $_[JebusBot::Constants::ARG2];
	$self->{'_ops'}     = [ @_[JebusBot::Constants::ARG3 .. $#_] ];
	
	$self->_parse_addressed;
	
	return $self;
}



=head2 JebusBot::Event::irc_nick

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->new_nick

The new nick that the person changed to.

=back

=cut

package JebusBot::Event::irc_nick;

use strict;
use warnings;
use base 'JebusBot::Event';

__PACKAGE__->_create_method('new_nick');

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->_parse_nickmask($_[JebusBot::Constants::ARG0]);
	
	$self->{'_new_nick'} = $_[JebusBot::Constants::ARG1];
	
	return $self;
}



=head2 JebusBot::Event::irc_public

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=item $event->msg

=item $event->addressed

=back

=cut

package JebusBot::Event::irc_public;

use strict;
use warnings;
use base 'JebusBot::Event';

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->_parse_nickmask($_[JebusBot::Constants::ARG0]);
	
	$self->{'_where'}   = $_[JebusBot::Constants::ARG1];
	$self->{'_msg'}     = $_[JebusBot::Constants::ARG2];
	$self->{'_channel'} = $self->{'_where'}->[0];
	
	$self->_parse_addressed;
	
	return $self;
}



=head2 JebusBot::Event::irc_notice

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=item $event->msg

=item $event->addressed

=back

=cut

package JebusBot::Event::irc_notice;

use strict;
use warnings;
use base 'JebusBot::Event::irc_public';



=head2 JebusBot::Event::irc_snotice

This class uses the following methds:

=over 2 

=item $event->msg

=back

=cut

package JebusBot::Event::irc_snotice;

use strict;
use warnings;
use base 'JebusBot::Event';

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->{'_msg'} = $_[JebusBot::Constants::ARG0];
	
	return $self;
}


=head2 JebusBot::Event::irc_msg

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=item $event->msg

=item $event->addressed

=back

=cut

package JebusBot::Event::irc_msg;

use strict;
use warnings;
use base 'JebusBot::Event';

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->_parse_nickmask($_[JebusBot::Constants::ARG0]);
	
	$self->{'_where'}   = $_[JebusBot::Constants::ARG1];
	$self->{'_msg'}     = $_[JebusBot::Constants::ARG2];
	$self->{'_channel'} = $self->nick;
	
	$self->_parse_addressed;    # still run _parse_addressed to strip ^$ME, but...
	$self->{'_addressed'} = 1;  # ...if we're /msg'ed then we're being addressed
		
	return $self;
}



=head2 JebusBot::Event::irc_ctcp_action

This class uses the following methds:

=over 2 

=item $event->nick

=item $event->hostname

=item $event->username

=item $event->channel

=item $event->msg

=item $event->addressed

=back

=cut

package JebusBot::Event::irc_ctcp_action;

use strict;
use warnings;
use base 'JebusBot::Event';

sub new {
	my $self = $_[0]->SUPER::new;
	
	$self->_parse_nickmask($_[JebusBot::Constants::ARG0]);
	
	$self->{'_where'}   = $_[JebusBot::Constants::ARG1];
	$self->{'_msg'}     = $_[JebusBot::Constants::ARG2];
	$self->{'_raw_msg'} = $self->{'_msg'};
	$self->{'_channel'} = $self->{'_where'}->[0];
	
	return $self;
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

L<perl>, , L<JebusBot::Plugin>, RFC 1459, L<Net::IRC>


=cut


1;

