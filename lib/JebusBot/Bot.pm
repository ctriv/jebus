package JebusBot::Bot;
#
# $Id: Bot.pm,v 1.9 2003/04/13 03:11:44 ctriv Exp $
#
#
# Stewie: "What's your email? Mine is loismustdie, all one word, @yahoo.com." 
#

=head1 NAME

JebusBot::Bot - Jebus's Spine

=head1 SYNOPSIS

 my $bot = JebusBot::Bot->new;
 
 $bot->run
 
=head1 DESCRIPTION

This class is the basic framework that ties all of Jebus's plugins together with the
L<POE::Component::IRC::Object> underpinings.  It is a hacked up version of 
L<Bot::Pluggable|Bot::Pluggable>.

=cut


use strict;
use warnings;

use JebusBot::Event;
use JebusBot::Constants qw(:console);

use base 'POE::Component::IRC::Object';

use POE;


=head1 Methods

=head2 new()

Creates a JebusBot::Bot object, pulling configuration from C<$JebusBot::Config>.

=cut

sub new {
	my ($class) = @_;
	
	my $config = $JebusBot::Config;
	
	my %args = (
		Server   => $config->get('server'),
		Port     => $config->get('port'),
		Nick     => $config->get('nick') ,    
		Username => $config->get('username'),
		Ircname  => $config->get('ircname') || 'Dog is my hero.',
		Plugins  => [ JebusBot::Plugins->plugins ],
	);
	
	if (my $pass = $config->get('password')) {
		$args{'Password'} = $pass;
	}
		
	return $class->SUPER::new(%args);
}


=head2 $bot->run

Starts the POE kernel up.

=cut

sub run { $poe_kernel->run }


=head2 $bot->add_plugin

Adds a plugin to the list of plugins the bot knows about.

Not recommended for the faint of heart.

=cut

sub add_plugin {
    my ($self, @plugins) = @_;
    push @{$self->{Plugins}}, @plugins;
}

sub plugins {
    my ($self) = @_;
    return @{$self->{Plugins}};
}



BEGIN {
    sub add_event {
        my ($class, $method) = @_;
                
        no strict q/refs/;
        
        *{"$method"} = sub {
			my $self = $_[OBJECT];
			
			shift(@_);
			
			my $event_class = "JebusBot::Event::$method";
			my $event       = $event_class->new(@_);
			
			foreach my $plugin ($self->plugins) {
				next unless my $meth = $plugin->can($method);
				
				$plugin->_event($event);
				
				# This is really like $plugin->$meth($event)
				my $ret = $meth->($plugin, $event);																
				
				$plugin->_event(undef);
				
				return if $ret;
			}
		};
    }
    
    my @methods = qw(
        irc_001 
        irc_join 
        irc_invite 
        irc_kick 
        irc_mode 
        irc_nick 
        irc_notice 
        irc_part 
        irc_ping 
        irc_quit
        irc_snotice
		
		
	);

	# These are special
	#	irc_public 
	#	irc_msg 
	#	irc_ctcp_action
	
	# Just action for now, more coming soon!
    #    irc_ctcp_finger
    #    irc_ctcp_version
    #    irc_ctcp_source
    #    irc_ctcp_userinfo
    #    irc_ctcp_clientinfo
    #    irc_ctcp_errmsg
    #    irc_ctcp_ping
    #    irc_ctcp_time
        
    #);
    
    foreach my $method (@methods) {
        __PACKAGE__->add_event($method);
    }
}

#
# These events are special
#
sub irc_msg {
	my $self = $_[OBJECT];
	
	shift(@_);

	my $event = JebusBot::Event::irc_msg->new(@_);
	
	$JebusBot::Console->put($event->nick . ' -> ' . $event->raw_msg, IRC_IN);
	$JebusBot::Console->put('I am being addressed: '. $event->msg, INFO);
	
	foreach my $plugin ($self->plugins) {
		next unless my $meth = $plugin->can('irc_msg');
		
		$plugin->_event($event);
		
		# This is really like $plugin->$meth($event)
		my $ret = $meth->($plugin, $event);																
		
		$plugin->_event(undef);
		
		return if $ret;
	}
}

sub irc_public {
	my $self = $_[OBJECT];
	
	shift(@_);

	my $event = JebusBot::Event::irc_public->new(@_);
	
	$JebusBot::Console->put($event->channel . ': <' . $event->nick . '> ' . $event->raw_msg, IRC_IN);
	$JebusBot::Console->put('I am being addressed: '. $event->msg, INFO) if $event->addressed;
	
	foreach my $plugin ($self->plugins) {
		next unless my $meth = $plugin->can('irc_public');
		
		$plugin->_event($event);
		
		# This is really like $plugin->$meth($event)
		my $ret = $meth->($plugin, $event);																
		
		$plugin->_event(undef);
		
		return if $ret;
	}
}

sub irc_ctcp_action {
	my $self = $_[OBJECT];
	
	shift(@_);

	my $event = JebusBot::Event::irc_public->new(@_);
	
	$JebusBot::Console->put($event->channel . ': * ' . $event->nick . ' ' . $event->raw_msg, IRC_IN);
	
	foreach my $plugin ($self->plugins) {
		next unless my $meth = $plugin->can('irc_ctcp_action');
		
		$plugin->_event($event);
		
		# This is really like $plugin->$meth($event)
		my $ret = $meth->($plugin, $event);																
		
		$plugin->_event(undef);
		
		return if $ret;
	}
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

L<perl>, L<JebusBot>, L<POE::Component::IRC::Object>, L<Bot::Pluggable>


=cut


1;
__END__
