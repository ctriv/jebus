package JebusBot::Services;
#
# $Id: Services.pm,v 1.2 2003/05/03 00:16:35 ctriv Exp $ 
#
# Stewie: Wait, Wait, I'v got it, I'v got it. If you cooked any slower, you wouldn't
#         need an egg timer, you'd need an egg calendar! Ah ha ha ha ha!! Oh that's 
#         right...    I went there. 
#

use strict;
use warnings;
use Carp ();

=head1 NAME

JebusBot::Services - We all need a little help

=head1 SYNOPSIS

 use JebusBot::Services ();
 
 JebusBot::Services::HTTP(http://somesite.com/ => sub {
 	my $res = shift;
 	
 	$self->send($res->content);
 	
 });
 
 JebusBot::Services::HTTP(
 	HTTP::Request->new(HEAD => http://slashdot.org/) => sub {
		my $res = shift;
		
		if ($res->is_sucess) {
			$self->send("slashdot is up");
		} else {
			$self->send("Error: " . $res->status_line);
		}
	}	
 );
 
 
 JebusBot::Services::DNS(
	['www.google.com', 'A', 'IN'] => sub { 		
		my ($answer, $error) = @_;
 		
 		if ($answer) {
	 		$self->send($answer->string);
	 	} else {
	 		$self->send("Error: $error);
	 	}
 		
 	}
 )
 
 
 	
   
 1; 

=head1 DESCRIPTION

Services Provide a simple interface to common tasks that would typically
be done wrong in a POE envirement (HTTP requests blocking) or would require
digging into the POE interface.

At this time one service is provided, HTTP, which the SYNOPOSIS documents.

=cut

use POE qw(Component::Client::HTTP Component::Client::DNS); 
use LWP;

POE::Component::Client::HTTP->spawn(
	Alias => 'http_ua',
	Agent => "JebusBot/$JebusBot::VERSION",
);

POE::Session->create(
	inline_states => {
		_start        => sub { $_[KERNEL]->alias_set('http'); },
		http_response => \&http_response,
		get           => sub {			  
			$_[HEAP]->{'callback'} = $_[ARG1];
			$_[KERNEL]->post(http_ua => request => http_response => $_[ARG0]);
		},
	},
);

sub HTTP {
	my ($req, $callback) = @_;
	
	return unless $req and $callback;
	
	Carp::croak "Not given a callback" unless UNIVERSAL::isa($callback, 'CODE');
	
	$req = ref $req ? $req : HTTP::Request ->new(GET => $req);
		
	$poe_kernel->post(http => get => ($req, $callback));	
}


sub http_response {
	my ($response_packet, $heap) = @_[ARG1, HEAP]; 
	
	my $res = $response_packet->[0]; 
	
	$heap->{'callback'}->($res);
}



POE::Component::Client::DNS->spawn(
	Alias => 'named',  
);

POE::Session->create(
	inline_states => {
		_start        => sub { $_[KERNEL]->alias_set('dns'); },
		dns_response  => sub { $_[HEAP]->{'callback'}->(@{$_[ARG1]}); },
		resolve       => sub {			  
			$_[HEAP]->{'callback'} = $_[ARG1];
			$_[KERNEL]->post(named => resolve => dns_response => @{$_[ARG0]});
		},
	},
);


sub DNS {
	my ($q, $callback) = @_;
	
	return unless $q and $callback;
	
	Carp::croak "Not given a callback" unless UNIVERSAL::isa($callback, 'CODE');
	
	unless (ref $q) {
		$q = [$q, 'A'];
	}
		
	$poe_kernel->post(dns => resolve => ($q, $callback));	
	
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

L<perl>, L<jebus>, L<JebusBot::Event>, L<JebusBot::Plugin>,
L<http://www.infobot.org/>, 

=cut


1;

