package JebusBot::Plugin::RSS;
#
# $Id: RSS.pm,v 1.7 2003/05/19 06:20:12 ctriv Exp $
#
# Stewie: "Hello mother, care to partake in one of your oh-so-exhilarating 
#          games of Peek-a-boo?" 
#

=head1 NAME

JebusBot::Plugin::Karma

=head1 PREREQUISITES

=over4 

=item *

XML::RSS

=item *

LWP

=item *

POE::Component::Client::HTTP

=back

=head1 PARAMETERS

None

=head1 PUBLIC INTERFACE

	# Add a site to the list
	<botname>, headlines for <site> are at http://<url>
	
	# Get the headlines for a site
	headlines for <site>

=head1 DESCRIPTION

Allows for the fetching of RSS feeds from arbitrary sites.

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

use XML::RSS ();
use JebusBot::Services ();
use JebusBot::Constants qw(:plugin);

use base 'JebusBot::Plugin';

use strict;
use warnings;

sub irc_public { &handler; }
sub irc_msg    { &handler; }

sub handler {
	my ($self, $event) = @_;
	
	my $msg = $event->msg;
	
	$msg =~ s/\?$//;	
	
	if ($event->addressed and $msg =~ m#^headlines\s+(?!(?:are|is))(?:for\s+)?(\S+)\s+(?:is|are at)\s*(http://\S+)#) {
		$self->add_headline(lc $1, $2);
		return DONE;
	}
	
	if ($msg =~ m/^headlines\s+(?!(?:are|is))(?:for\s+)?(.*)\s*$/) {
		$self->show_headlines(lc $1);
		return DONE;
	}
		
	return NEXT;
}

sub add_headline {
	my ($self, $key, $url) = @_;
	
	$self->data->store($key => { 
		'url'     => $url, 
		'time'    => 0, 
		'content' => '',
	});
	
	$JebusBot::Console->put("RSS: headlines $key => $url");
	
	$self->send("Got it.");
}

sub show_headlines {
	my ($self, $key) = @_;
	
	my $cache = $self->data->get($key);
	
	unless ($cache) {
		$self->send("I don't know where ${key}'s RSS feed lives");
		return;
	}
	
	my $now = time;
	
	if ($now - $cache->{'time'} <= 30 * 60) {
		$JebusBot::Console->put("RSS: cache hit: $key");
		$self->send($cache->{'content'});
		return;
	}
			
	# This is one of the tricky bits of Jebus.  We're going to fire
	# off an ansyncronous request for the RSS file, by the time we get
	# an anwer, $self will be off doing somethign else, so even though
	# we can keep track of $self in the closure, we still need to have our 
	# own copy for this "thread" -- XXX This needs to be in the docs.
	my $clone = $self->clone;
	
	$JebusBot::Console->put("RSS: fetching $cache->{'url'}");
	
	JebusBot::Services::HTTP($cache->{'url'} => sub {
		my $res = shift;
 	
 		unless ($res->is_success) {
 			$clone->send("Couldn't fetch headlines");
 			return;
 		}
 	
 		my $rss = XML::RSS->new;
 		 		
 		$rss->parse($res->content); 		 		
 		
 		my @headlines;
 		foreach my $item (@{$rss->{'items'}}[0 .. 9]) {
 			last unless $item;
 			
 			push(@headlines, $item->{'title'});
 		}
 		
 		my $content = $rss->channel('link') . ' -- ' . join(', ' => @headlines);
 		
 		$clone->data->store($key => {
 			'url'     => $cache->{'url'},
 			'time'    => time,
 			'content' => $content,
 		});
 		
 		$clone->send($content);
 	
	});
	
	return DONE;
}
  
1; 
