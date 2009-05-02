package JebusBot::Plugin::Seen;
#
# $Id: Seen.pm,v 1.9 2003/05/19 06:20:12 ctriv Exp $
#
# Stewie: "Hello mother, care to partake in one of your oh-so-exhilarating 
#          games of Peek-a-boo?" 
#

__PACKAGE__->data_attributes({
 	nick        => 'varchar(32)',
 	msg         => 'varchar(255)',
 	time        => 'int(11)',
 	channel     => 'varchar(32)',
 	primary_key => 'nick',
 });
 

use JebusBot::Constants qw(:plugin);

use base 'JebusBot::Plugin';

use Time::Duration qw(ago);

use strict;
use warnings;

sub irc_public {
    my ($self, $event) = @_;
    
    my $ret = NEXT;
    
    if ($event->msg =~ m/^seen ([^\s?]+)/) {
    	$self->send($self->last_seen(lc $1));
    	$ret = DONE;
    }
        
    $self->data->store(lc $event->nick => {
    	'time'    => time, 
    	'msg'     => $event->raw_msg,
    	'channel' => $event->channel,
    });
        
    return $ret;
}


sub irc_ctcp_action {
	my ($self, $event) = @_;

	my $msg = '* ' . $event->nick . ' ' . $event->raw_msg;
		
	$self->data->store(lc $event->nick => {
		'time'	  => time, 
		'msg'	  => $msg,
		'channel' => $event->channel,
	});
	
	return NEXT;
}


sub last_seen {	
	my ($self, $nick) = @_;
	
	my $seen = $self->data->get($nick);
		
	if ($seen) {
		my $time = localtime($seen->{'time'});
		my $ago  = ago(time - $seen->{'time'});
		
		return qq{$nick was last seen on $seen->{'channel'} $ago, saying "$seen->{'msg'}" [$time]};
	} else {
		my $message = $self->config->{'unknownmsg'};
		return qq{I've never met a "$nick".  $message};
	}
}
  
1; 
