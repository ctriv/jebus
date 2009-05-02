package JebusBot::Filter;
#
# $Id: Filter.pm,v 1.5 2003/04/08 09:56:03 ctriv Exp $ 
#
# Stewie: Wait, Wait, I'v got it, I'v got it. If you cooked any slower, you wouldn't
#         need an egg timer, you'd need an egg calendar! Ah ha ha ha ha!! Oh that's 
#         right...    I went there. 
#

use strict;
use warnings;

=head1 NAME

JebusBot::Filter - Ye who controls the information...

=head1 SYNOPSIS

 package JebusBot::Filter::Who;
 
 use base 'JebusBot::Filter';
 
 use strict;
 use warnings;
 
 #
 # This is too wrong for words....
 #
 sub filter {
	 my ($class, $event) = @_;
	 
     my $msg = $event->msg;
     
     $msg =~ s/who/$event->nick/egs;
     
     $event->msg($msg);
 }
 
   
 1; 

=head1 DESCRIPTION

Filters provide a way to filter event objects.  If you want to write a filter, 
just create a module named something like C<JebusBot::Filter::MyFilter> and 
have it inherate from C<JebusBot::Filter>.  You should create a class method
called C<filter()>.  

C<filter()> will be passed an event object, simply use the event object's 
methods to manipulate the data, this class will do the right magic so that
your changes get where they need to be. See <JebusBot::Event::filter()> for
more information.

=head2 JebusBot::Filter->load_filter($name)

Loads the required class for a filter and returns the fully qualified
classname for the filter.

=cut

my %loaded_filters;

sub load_filter {
	shift;
	my $filter = shift;
	
	my $class = join('::', __PACKAGE__, $filter);
	
	unless ($loaded_filters{$class}) {
		eval "require $class";
		
		die $@ if $@;
		
		$loaded_filters{$class}++;
	}
	
	return $class;
}

=head2 $filter_class->apply_filter

Sets up the args for C<filter()> and calls it.

=cut

sub apply_filter {
	my ($class, $event) = @_;
	
	my $clone = $event->clone;
	
	$class->filter($clone);
	
	return $clone;
}

sub filter { die __PACKAGE__ . ' is only an interface.'; }

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

