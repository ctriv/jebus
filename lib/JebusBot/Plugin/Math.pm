package JebusBot::Plugin::Math;
#
# $Id: Math.pm,v 1.1 2003/05/12 06:16:22 ctriv Exp $
#
# British Girl: Ew! Your breath smells like kitty litter! 
# Stewie:       I was curious! 
#

=head1 NAME

JebusBot::Plugin::Math

=head1 PREREQUISITES

None

=head1 PARAMETERS

None

=head1 PUBLIC INTERFACE

	2+3
	2/3
	2**3
	etc...

=head1 DESCRIPTION

Evaluates mathematical expressions of the perl dialect.

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


use JebusBot::Constants qw(:plugin);
use Safe;

use base 'JebusBot::Plugin';

use strict;
use warnings;

my %digits = ( 
	first   => '1',
	second  => '2',
	third   => '3',
	fourth  => '4',
	fifth   => '5',
	sixth   => '6',
	seventh => '7',
	eighth  => '8',
	ninth   => '9',
	tenth   => '10',
	one     => '1',
	two     => '2',
	three   => '3',
	four    => '4',
	five    => '5',
	six     => '6',
	seven   => '7' ,
	eight   => '8',
	nine    => '9',
	ten     => '10',
); 

my $safe = Safe->new;

sub irc_public { &handler }
sub irc_msg    { &handler }


sub handler {
	my ($self, $event) = @_;
	
	my $msg = $event->msg;
	
	return NEXT unless $msg !~ m/^\s*$/ and $msg !~ m/(\d+\.){2,}/;
	
	$msg =~ s/\s*\?\s*$//;
	
	foreach (keys %digits) {
		$msg =~ s/$_/$digits{$_}/g;
	}
	
	while ($msg =~ m/(exp ([\w\d]+))/) {
		my $exp = $1;
		my $val = exp($2); 
		$msg    =~ s/$exp/+$val/g;
	}	
	
	while ($msg =~ m/(hex2dec\s*([0-9A-Fa-f]+))/) {
		my $exp = $1;
		my $val = hex($2);
		$msg =~ s/$exp/+$val/g;
	}  
	
	if ($msg =~ m/^\s*(dec2hex\s*(\d+))\s*\?*/) {
		my $exp = $1;
		my $val = sprintf('%x', $2);
		$msg    =~ s/$exp/+$val/g;
	}
	
	my $e = exp(1);
	$msg =~ s/\be\b/$e/;
	
	while ($msg =~ m/(log\s*((\d+\.?\d*)|\d*\.?\d+))\s*/) {
		my $exp = $1;
		my $res = $2;
		my $val;
		
		if ($res == 0) { 
			$val = 'Infinity';
		} else { 
			$val = log($res); 
		}
		
		$msg =~ s/$exp/+$val/g;
	}
	
	while ($msg =~ m/(bin2dec ([01]+))/) {
		my $exp = $1;
		my $val = join ('', unpack ('B*', $2)) ;
	    $msg    =~ s/$exp/+$val/g;
	}
	
	while ($msg =~ m/(dec2bin (\d+))/) {
		my $exp = $1;
	    my $val = join('', unpack('B*', pack('N', $2)));
		
		$val =~ s/^0+//;
	    
	    $msg =~ s/$exp/+$val/g;
	}
	
	$msg =~ s/ to the / ** /ig;
	$msg =~ s/\btimes\b/\*/ig;
	$msg =~ s/\bdiv(ided by)? /\/ /ig;
	$msg =~ s/\bover /\/ /ig;
	$msg =~ s/\bsquared/\*\*2 /ig;
	$msg =~ s/\bcubed/\*\*3 /ig;
	$msg =~ s/\bto\s+(\d+)(r?st|nd|rd|th)?( power)?/\*\*$1 /ig;
	$msg =~ s/\bpercent of/*0.01*/ig;
	$msg =~ s/\bpercent/*0.01/ig;
	$msg =~ s/\% of\b/*0.01*/ig;
	$msg =~ s/\%/*0.01/g;
	$msg =~ s/\bsquare root of (\d+)/$1 ** 0.5 /ig;
	$msg =~ s/\bcubed? root of (\d+)/$1 **(1.0\/3.0) /ig;
	$msg =~ s/ of / * /i;
	$msg =~ s/(bit(-| )?)?xor(\'?e?d( with))?/\^/ig;
	$msg =~ s/(bit(-| )?)?or(\'?e?d( with))?/\|/ig;
	$msg =~ s/bit(-| )?and(\'?e?d( with))?/\& /ig;
	$msg =~ s/(plus|and)/+/ig;
	
	
	if ($msg =~ m/^\s*[-\d*+\s()\/^\.\|\&\*\!]+\s*$/
	&&  $msg !~ m/^\s*\(?\d+\.?\d*\)?\s*$/
	&&  $msg !~ m/^\s*$/
	&&  $msg !~ m/^\s*[( )]+\s*$/)
	{
		my $ans = $safe->reval($msg);
		
		if ($ans =~ /^[-+\de\.]+$/) {
			$ans =~ s/\.0+$//;
			$ans =~ s/(\.\d+)000\d+/$1/; 
			if (length($ans) > 30) {
				$ans = 'a number with quite a few digits...';
			}

		    $self->send($ans);
		    
		    return DONE;
		} 
	}
	
	return NEXT;
}
		
1; 
