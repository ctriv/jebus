package JebusBot::Plugin::Karma;
#
# $Id: Karma.pm,v 1.10 2003/05/19 06:20:12 ctriv Exp $
#
# Meg:    Dad I'm finally going to be a flag girl! 
# Brian:  Well thats terrific Meg. 
# Stewie: Ah yes yes..... Well, now we know where you'll be when the boys don't call! 
# Stewie and Brian: (snorting and laughing like nerds) 
#

=head1 NAME

JebusBot::Plugin::Karma

=head1 PREREQUISITES

None

=head1 PARAMETERS

=head2 MustAddress

	<Plugin Karma>
		MustAddress On|Off
	</Plugin>

Is addressing needed to use the karma plugin.

=head1 PUBLIC INTERFACE

	thing++
	thing--
	karma [for] thing

=head1 DESCRIPTION

Tracks the karma of things.

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

__PACKAGE__->data_attributes({
 	thing       => 'varchar(32)',
 	karma       => 'int(11)',
 	primary_key => 'thing',
 }); 

use JebusBot::Constants qw(:plugin);

use base 'JebusBot::Plugin';

use strict;
use warnings;

my %values = (
	'++' => 1,
	'--' => -1,
);


sub irc_public {
    my ($self, $event) = @_;
    
    return NEXT if !$event->addressed and $self->config->{'must_addr'};

	my $msg = $event->msg;
	
	THING: while ($msg =~ m/(?:\((.*?)\)|([^(++)(--)\s]+))(\+\+|--)/g) {
		my ($key, $action) = (lc($1 || $2), $3);
		
		if ($key eq lc($event->nick)) {
			$self->send("Please do not karma yourself.", $event->nick);
			next THING;
		}
		
		$self->update_karma($key, $action);
		return DONE;
	}
	
	if ($event->msg =~ m/^karma\s+(?:for\s+)?([^?]+)\??/) {
		$self->send($self->karma($1));
		return DONE;
	}
        
    return NEXT;
}

sub update_karma {
	my ($self, $thing, $action) = @_;
	
	my $karma = $self->data->get($thing);
	
	$JebusBot::Console->put("Karma: adding $values{$action} to $thing");
	
	if ($karma) {
		$karma->{'karma'} += $values{$action};
		
		$self->data->update($thing => $karma);
	} else {
		$self->data->insert($thing => {
			karma => $values{$action},
			thing => $thing,
		});
	}
}

sub karma {
	my ($self, $thing) = @_;
	
	my $karma = $self->data->get($thing);
	
	if (!$karma || $karma->{'karma'} == 0) {
		return "$thing has neutral karma.";
	} else {
		return "$thing has karma of $karma->{'karma'}.";
	}
}

  
1; 
