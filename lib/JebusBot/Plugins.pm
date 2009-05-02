package JebusBot::Plugins;
#
# $Id: Plugins.pm,v 1.5 2003/05/03 00:21:11 ctriv Exp $
#
# Stewie: "Hello mother, care to partake in one of your oh-so-exhilarating 
#          games of Peek-a-boo?" 
#

use strict;
use warnings;

use JebusBot::Constants qw(:console);

=head1 NAME

JebusBot::Plugins - Gather the faithfull

=head1 SYNOPSIS

 JebusBot::Plugins::load_plugins()
 
 my @plugins = JebusBot::Plugins->plugins
 
=head1 DESCRIPTION

This class loads the plugins needed as specified in the config file.

=cut

my @plugins;

sub load_plugins {	
	my @required = @{$JebusBot::Config->get('loadplugin')};
	
	foreach my $mod (@required) {
		my $class = "JebusBot::Plugin::$mod";
		
		eval "require $class;";
		
		$JebusBot::Console->put("Loaded Plugin $mod", INFO);
		
		die $@ if $@;
	
		push(@plugins, $class->new);
	}
}
	
sub plugins { @plugins; }

=head1 AUTHOR

Chris Reinhardt, <F<perl@triv.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 Chris Reinhardt

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

=head1 SEE ALSO

L<perl>, L<jebus>, L<jebusbot.conf>, L<JebusBot::Plugin>,
L<http://www.infobot.org/>, 

=cut

1;
__END__
	
	
