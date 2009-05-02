package JebusBot;
#
# $Id: JebusBot.pm,v 1.10 2003/05/19 06:21:11 ctriv Exp $
#
#
# Stewie: I have an army to raise and I must get to Managua at once! 
#         I require a window seat and an in-flight Happy Meal. But no pickles! 
#         Oh, God help you if I find pickles! 
#

require 5.006;

use strict;
use warnings;
use Carp;

use JebusBot::Config  ();
use JebusBot::Bot     ();
use JebusBot::Plugins ();
use JebusBot::Data    ();
use JebusBot::Console ();

use File::Spec;
use Data::Dumper;

our $VERSION = '0.01';

=head1 NAME

JebusBot - An IRC Robot

=head1 DESCRIPTION

Jebus is an IRC rebot that strives to implement all the features of Infobot, 
with improvements.  Jebus is built on top of POE, and is completely plugin 
based. 

=head1 run(%args)

This is the 'main' function of the entire bot.  It sets up the configuration
data, loads the plugins, and fires off the bot object.

=cut

sub run {
	unless (@_ % 2 == 0) {
		croak __PACKAGE__ . '::run() called with an odd number of parameters.';
	}

	my %args = @_;

	$JebusBot::Config  = JebusBot::Config->new(%args);
	$JebusBot::Console = JebusBot::Console->new;
	
	JebusBot::DBI->init;
	
	#print Dumper($JebusBot::Config);
	#exit;
	
	JebusBot::Plugins::load_plugins();
	
	$JebusBot::Bot = JebusBot::Bot->new;
	
	$JebusBot::Bot->run;
}

=head1 Globals

=head2 $JebusBot::Config

A L<JebusBot::Config|JebusBot::Config> object.  Use this instead of
creating your own.

=head2 $JebusBot::Bot

The global L<JebusBot::Bot|JebusBot::Bot> object for jebus. It is used 
internally to do deep dark voodoo, such as join channels, listen, and 
talk on IRC.

=head1 Utility Functions

=head2 JebusBot::bot_root_relative($file)

Returns a path relative to the C<BotRoot> configuration directive.

=cut

sub bot_root_relative {
	my ($file) = @_;
	
	return $file =~ m:^/: ? $file : File::Spec->catfile($JebusBot::Config->get('botroot'), $file);
}


=head2 JebusBot::bot_names()

Returns a list of all the names that Jebus is looking for, see the 
C<ExtraNicks> and C<Nick> configuration directives for more details.

=cut

sub bot_names {
	return (
		$JebusBot::Config->get('nick'), 
		split(m/\s+/, $JebusBot::Config->get('extranicks'))
	);
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

L<perl>, L<jebus>, L<JebusBot::Config>, L<JebusBot::Plugin>, L<POE>,
L<http://www.infobot.org/>, 

=cut


1;
__END__
