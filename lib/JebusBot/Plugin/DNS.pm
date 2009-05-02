package JebusBot::Plugin::DNS;
#
# $Id: DNS.pm,v 1.3 2003/05/19 06:20:12 ctriv Exp $
#
# Stewie: "Hello mother, care to partake in one of your oh-so-exhilarating 
#          games of Peek-a-boo?" 
#

=head1 NAME

JebusBot::Plugin::DNS

=head1 PREREQUISITES

POE::Component::CLient::DNS

=head1 PARAMETERS

None

=head1 PUBLIC INTERFACE

	(nslookup|DNS [for]) <host>
	dig host [type] [@server]  # UNIMPLEMENTED

=head1 DESCRIPTION

Looks up DNS entries for the given host using Net::DNS.

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

use JebusBot::Constants qw(:plugin);
use JebusBot::Services ();

use base 'JebusBot::Plugin';

use strict;
use warnings;

sub irc_msg    { &handler }
sub irc_public { &handler }

sub handler {
	my ($self, $event) = @_;
	
	local $_ = $event->msg;
	
	if (m/^(?:nslookup|DNS\s*(?:for)?)\s+(\S+)/i) {
		return $self->nslookup($1);
	}
	
	#if (m/^dig\s+(\S+)\s*(\w*)\s*\@?(\S*)/i) {		
	#	return $self->dig($1, $2, $3);
	#}
	
	return NEXT;
}


sub nslookup {
	my ($self, $name) = @_;
	
	$JebusBot::Console->put("DNS: looking up '$name IN A'");
	
	my $clone = $self->clone;
	
	JebusBot::Services::DNS($name => sub {
		my ($packet, $error) = @_;
		
		if ($packet) {
			my @answers = $packet->answer;
			
			if (@answers) {
				$clone->send_nslookup_answer($name, @answers);
			} else {
				$clone->send("I can't seem to find $name");
			}
		} else {
			$clone->send("Couldn't look up $name: $error");
		}
	});
}


sub send_nslookup_answer {
	my ($self, $name, @answers) = @_;
		
	my @ips = map { $_->address } grep { $_->type eq 'A' } @answers;
	
	my $ans = "$name is " . (@ips == 1 ? $ips[0]              :
							 @ips == 2 ? join(' and ', @ips)  :
							             join(', ', @ips[0 .. $#ips -1], "and $ips[-1]"));
							          
	$self->send($ans);
}
							          
							          
  
1; 
