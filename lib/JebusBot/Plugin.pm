package JebusBot::Plugin;
#
# $Id: Plugin.pm,v 1.15 2003/05/19 06:20:12 ctriv Exp $
#
# Stewie: "But Mother, I thought you said they were lazy like the dirty Mexicans..."
#

use strict;
use warnings;

use JebusBot::Constants qw(:console);

=head1 NAME

JebusBot::Plugin - Slowy Build Jebus's mind.

=head1 SYNOPSIS

 package JebusBot::Plugin::Slap;

 use JebusBot::Constants qw(:plugin);
 
 use base 'JebusBot::Plugin';
 
 use strict;
 use warnings;
 
 sub new {
	 my ($class) = @_;
	 
	 my $self = $class->SUPER::new;
	 
	 $self->{'message'} = $self->config->{'message'};
	 	 
	 return $self;	
 }
 
 
 sub irc_public {
	 my ($self, $event) = @_;
	 
	 if ($event->addressed) {
		 $self->send("$self->{'message'}, " . $event->nick);
	 }
	 
	 return NEXT;
 }
   
 1; 


=head1 DESCRIPTION

Jebus is a completely plugin based bot.  It's also event based, but I digress.  
The basic jist is that plugins are classes.  If that class has a method for
an event then that method will be called for that event.  These classes
are objected based, and should subclass C<JebusBot::Plugin>.  

Each method can return C<DONE> or C<NEXT>.  C<DONE> indicated that no 
further processing should be done for this event, while C<NEXT> simply
means that this class is done with the event.  

=head1 Writing a plugin.  

Jebus plugins are classes that define certain methods. These classes should inherit
from C<JebusBot::Plugin>  Each object instance of that class should be a blessed
hashref, as C<JebusBot::Plugin> expects your objects to be hashes.

You should have a creator called C<new()>.  C<new()> is called once in
the lifetime of the bot, plugin objects are not created per event.
Within your object, keys starting with C<_> are reserved for internal
use.

=head1 Plugin Data Attributes

Plugins in Jebus have the option of specifying the format that their records are in.
This allows for SQL databases to use native tables to store the data, giving a nice
speed boost.  

Here is an example of the method used for specifying the attributes, in the 
future this will be better documented.

 __PACKAGE__->data_attributes({
 	nick        => 'varchar(32)',
 	msg         => 'varchar(255)',
 	time        => 'int(11)',
 	channel     => 'varchar(32)',
 	primary_key => 'nick',
 # 	index       => ['time'],  just as an example
 });

=cut

sub data_attributes {
	my ($class, $attr) = @_;
	
	unless (UNIVERSAL::isa($attr, 'HASH')) {
		die "$class does not impletement data_attributes() correctly. Must return a hashref\n";
	}
	
	JebusBot::Data->create_pluginfo($class, $attr);
}

=head1 Sending output.

The output methods come from L<POE::Component::IRC::Object|POE::Component::IRC::Object>,
who stole them from L<POE::Component::IRC|POE::Component::IRC>, who stole
them from L<Net::IRC|Net::IRC>, who stole them from the relevent RFCs.  So look there! :)

=cut

BEGIN {

	my @outgoing_methods = qw(
				rehash
				restart
				quit
				version
				time
				trace
				admin
				info
				away
				users
				wallops
				motd
				who
				nick
				oper
				invite
				squit
				kill
				privmsg
				notice
				join
				summon
				sconnect
				whowas
				stats
				links
				mode
				part
				names
				list
				whois
				ctcp
				ctcpreply
	);
	
	no strict q/refs/;
	
	foreach my $method (@outgoing_methods) {
		*{"$method"} = sub {
			my ($self, @args) = @_;
						
			return $JebusBot::Bot->$method(@args);
		};
	}
}

=head1 Important Events

=head2 irc_001

Called right after the connection is up and running.

	sub irc_001 {
		my ($self) = @_;
		
		$self->join('#perl');
	}
	
=head2 irc_error

	sub irc_error {
		my ($self, $event) = @_;
		
		my $error = $event->error;
		
		die "IRC Error: $error\n";
	}

You get this whenever the server sends you an ERROR message. Expect
this to usually be accompanied by the sudden dropping of your
connection. C<<$event->error>> contains the error message

=head2 irc_join

	sub irc_join {
		my ($self, $event) = @_;
		
		my $channel = $event->channel;
		my $nick    = $event->nick;
		
		$self->send("Welcome to $channel $nick!");
		
		return NEXT;
	}
	
Note that current_channel is set up for you when this method is called.

=head2 irc_invite

	sub irc_invite {
		my ($self, $event) = @_;
		
		my $nick = $event->nick
		
		$self->join($event->channel);
		
		$self->send("I'm here $nick", $event->channel);
		
		return DONE;
	}

=head2 irc_kick

	sub irc_kick {
		my ($self, $event) = @_;
		
		my $channel = $event->channel;
		my $nick    = $event->nick;
		my $luser   = $event->luser;
		my $msg		= $event->msg;
		
		$self->send("Right on $nick, $luser has no place in $channel");
		
		$LOG->logthis("$luser kicked off of $channel: $msg);
		
		return NEXT;
	}
	
Called when a user is kicked off the channel.

=head2 irc_mode

	sub irc_mode {
		my ($self, $event) = @_;
		
		my $nick   = $event->nick;
		my $thing  = $event->thing;
		my $string = $event->string;
		my $ops    = $event->ops;
		
		$LOG->logthis("Mode set for $thing: $string by $nick");
		
		return NEXT;
	}

Sent whenever someone changes a channel mode in your presence, or when
you change your own user mode. C<<$event->ops>> is an arrayref of the
operands to the mode string (nicks, hostmasks, channel keys, whatever).

=head2 irc_nick

	sub irc_nick {
		my ($self, $event) = @_;
		
		return NEXT if $even->nick eq $JebusBot::Config->get('nick');
		
		my $nick     = $event->nick;
		my $new_nick = $event->new_nick;
	
		# private message	
		$self->send("First you're $nick, then you're $new_nick, stop it.", $new_nick);
		
		return NEXT;
	}

Sent whenever you, or someone around you, changes nicks. 

=head2 irc_notice

	sub irc_notice {
		my ($self, $msg, $nick, $where) = @_;
		
		$self->send("Why: $msg!");
		
		return NEXT;
	}

Sent whenever you receive a NOTICE command. 

=head2 irc_part

	sub irc_part {
		my ($self, $nick) = @_;
		
		$self->send("bye bye $nick");
		
		return NEXT;
	}


Sent whenever someone leaves a channel that you're on. 

=head2 irc_ping

	sub irc_ping {
		my ($self) = @_;
		
		$LOG->logthis("Ping?!");
		
		return NEXT;
	}

An event sent whenever the server sends a PING query to the
client. (Don't confuse this with a CTCP PING, which is another beast
entirely. If unclear, read the RFC.) Note that POE::Component::IRC will
automatically take care of sending the PONG response back to the
server for you, although you can still register to catch the event for
informational purposes.


=head2 irc_public

Sent whenever you receive a PRIVMSG command that was sent to a
channel. 

 	sub irc_public {
		my ($self, $event) = @_;
		
		if ($event->msg =~ m/perl/i) {
			$self->send("Larry is cooler than your mom!");
		}
		
		return NEXT;
	}
	
This is by far the most commonly used, and useful event in Jebus.  The
event object passed to this method has lots of useful information in it,
see L<JebusBot::Event|JebusBot::Event> for details.
	
=head2 irc_msg

	sub irc_msg {
		my ($self, $event) = @_;
		
		$self->send("Lets get close " . $event->nick);
		
		return NEXT;
	}
		
Sent whenever you receive a PRIVMSG command that was addressed to you
privately. 


=head2 irc_quit

	sub irc_quit {
		my ($self $event) = @_;
		
		$self->last_seen($event->nick => $even->msg);
		
		return NEXT;
	}

Sent whenever someone on a channel with you quits IRC (or gets KILLed). 
C<<$event->msg>> is the clever, witty message they left behind on the
way out.


=head1 CONNIVENCE METHODS

=head2 send($msg, $channel)

Sends output to C<$channel>, or the current channel if $channel is not given.

=cut

sub send {
	my ($self, $msg, $channel) = @_;
	
	$channel ||= $self->{'_event'}->channel;
	
	$JebusBot::Console->put("$channel: $msg", IRC_OUT);
	
	$self->privmsg($channel, $msg);
}

=head2 action($msg, $channel)

Sends a CTCP ACTION to given channel, or the current channel if no channel
is given.

=cut

sub action {
	my ($self, $msg, $channel) = @_;
	
	$channel ||= $self->{'_event'}->channel;
	
	$JebusBot::Console->put("$channel: * $msg", IRC_OUT);
	
	$self->ctcp($channel, "ACTION $msg");
}


=head2 clone()

Sometimes it is helpfull to have a clone of your plugin object,
especially during asynchronous activities, see L<JebusBot::Services> 
for details.

=cut

sub clone { bless({%{$_[0]}}, ref $_[0]) }


=head2 new()

JebusBot::Plugin does define and basic C<new()> constructor that your
plugin can use.  It simply returns a hashref blessed into the correct
class.

=cut

sub new { return bless({}, $_[0]) }


=head2 data()

Returns a L<JebusBot::Data|JebusBot::Data> object setup for your plugin

=cut

sub data {
	my ($self) = @_;
	
	$self->{'_data'} ||= JebusBot::Data->new($self);

	return $self->{'_data'};
}


=head2 config

Returns a hashref containing the configuration directives for this plugin.

=cut

sub config {
	my ($self) = @_;
	
	unless ($self->{'_config'}) {
		my $class = ref $self;
		
		$class =~ s/^.*:://;
		
		$self->{'_config'} = $JebusBot::Config->plugin($class);
	}
	
	return $self->{'_config'};
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

L<perl>, , L<JebusBot::Event>, RFC 1459, L<Net::IRC>


=cut

#
# set the event so that $plugin->send works the way we want it too
#
sub _event {
	my ($self, $event) = @_;
	
	$self->{'_event'} = $event;
}



1;
__END__

