package JebusBot::Constants;
#
# $Id: Constants.pm,v 1.6 2003/04/22 08:23:21 ctriv Exp $
#
# Guy at Airport: Aren't you a little young to be traveling alone? 
# Stewie:         Aren't you a little old to be wearing braces? 
#

=head1 NAME

JebusBot::Constants - Handy constants.

=head1 SYNOPSIS

 use JebusBot::Constants qw(:plugin)
 
=head1 DESCRIPTION

This class provides constants for use by plugins as described below.  Other 
constants are provided by this module, but they are not the concern of a 
plugin author.

=cut

use strict;
use warnings;

use Exporter ();

use POE;

our @EXPORT = ();
our %EXPORT_TAGS = (
	'plugin'  => [qw(DONE NEXT PLUG_INFO)],
	'poe'	  => [qw(OBJECT SENDER ARG0 ARG1 ARG2 ARG3 ARG4 ARG5 ARG6 ARG7 ARG8)],
	'console' => [qw(IRC_IN IRC_OUT PLUG_INFO INFO NOTICE DEBUG)],
);

push(@{$EXPORT_TAGS{'all'}}, @{$_}) for values %EXPORT_TAGS;

our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

*import = \&Exporter::import;

=head1 Plugin Constants

The plugin constants can be importated with C<:plugin> tag.

=head2 DONE

When returned by a plugin method, it indicates that no futher plugins
should be passed the event.

=head2 NEXT

Let the next plugin in line handle the event as well.

=cut

use constant DONE => 1;
use constant NEXT => 0;

=head1 Console Constants

=head2 PLUG_INFO

General information for a plugin.  This is also exported by the C<:plugin> tag.

=head2 INFO

General information, like "I am being addressed"

=head2 IRC

Raw IRC strings, used internally.

=head2 DEBUG

Debugging information

=cut

use constant IRC_IN    => 0;
use constant IRC_OUT   => 1;
use constant NOTICE    => 2;
use constant INFO      => 4;
use constant PLUG_INFO => 5;
use constant DEBUG     => 10;


=head1 AUTHOR

Chris Reinhardt, <F<perl@triv.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 Chris Reinhardt

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

=head1 SEE ALSO

L<perl>, L<jebus>, L<JebusBot::Bot>, L<JebusBot::Plugin>,
L<http://www.infobot.org/>, 

=cut

1;
__END__
