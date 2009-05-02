#!/usr/bin/env perl
# $Id: jebusbot.PL,v 1.2 2003/05/19 06:20:40 ctriv Exp $

use Config;
use File::Basename qw[basename dirname];
use Cwd;

my $origdir = cwd;
chdir dirname $0;
my $file = basename( $0, '.PL' );
$file .= '.com' if $^O eq 'VMS';

open(OUT, '>', $file) or die "Can't create $file: $!";

print OUT "$Config{startperl}\n";

print OUT <<'GROK_THIS';
#
# $Id: jebusbot.PL,v 1.2 2003/05/19 06:20:40 ctriv Exp $
#
# Stewie: "Damn you, vile woman! You've impeded my work since the day I escaped 
#          from your wretched womb. When you least expect it your uppance will come!" 
#

require 5.006;
use strict;
use warnings;
use Getopt::Long;

use lib qw[lib ../lib];
use JebusBot;

my %args;

GetOptions('config=s', \%args);

=head1 NAME 

jebusbot -- The IRC bot you hoped would never be.

=head1 USAGE

jebusbot [--config=<config file>]

=cut

JebusBot::run(%args);

exit 0;

=head1 AUTHOR

Chris Reinhardt, <F<perl@triv.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 Chris Reinhardt

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

=head1 SEE ALSO

L<perl>, L<Bot::Jebus>, L<Bot::Jebus::Config>, L<Bot::Jebus::Plugin>, L<POE>,
L<http://www.infobot.org/>
=cut

GROK_THIS

close OUT;

chmod 0755, $file;

chdir $origdir;

__END__
