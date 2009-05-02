package JebusBot::Config;
#
# $Id: Config.pm,v 1.3 2003/04/08 10:06:17 ctriv Exp $
#
#
# Stewie: "well, well mother, we meet again" 
#

=head1 NAME

JebusBot::Config - Read the good file.

=head1 SYNOPSIS

 my $config = JebusBot::Config->new(config => $file);
 
 $config->get('nick');
 $config->set(nick => 'Jebus');
 $config->clear('nick');
 
 my $plugin_config = $config->plugin('Karma');
 
=head1 DESCRIPTION

This class is a wrapper around L<Config::General|Config::General>.  It
provides an interface to the Jebus Configuration file.  See
L<jebusbot.conf|jebusbot.conf> for more information.

=cut

use strict;
use warnings;

use File::Spec      ();
use Config::General ();
use Carp            ();

=head1 Methods

=head2 new(%args)

Returns a JebusBot::Config object, the following args are valid:

=over 2

=item config

Path to the configuration file.

=cut

sub new {
	my ($class, %args) = @_;
	
	my @guesses = qw(
		jebusbot.conf 
		../etc/jebusbot.conf 
		/usr/local/jebusbot/etc/jebusbot.conf
	);
	
	my $self = bless({}, $class);
	
	unshift(@guesses, $args{'config'}) if $args{'config'};
	
	foreach my $file (@guesses) {
		if (-e $file and -f _ and -o _) {
			$self->read_file($file) and last;
		}
	}
	
	unless ($self->{'config'}) {
		die "Could not find configuration file\n";
	}
	
	return $self;
}


sub read_file {
	my ($self, $file) = @_;
	
	my $conf = Config::General->new(
		-ConfigFile     => $file,
		-LowerCaseNames => 1,
		-AutoTrue       => 1,
	) || return;
	
	$self->{'config'} = { $conf->getall };
	
	return 1;
}


=head2 $config->get($key)

Returns the value for C<$key>.  Note that all keys are lowercase.

=cut

sub get {
	my ($self, $var) = @_;
	
	return $self->{'config'}->{$var};
}


=head2 $config->set(key => $new_value)

Sets a new value for a given key.

=cut

sub set {
	my ($self, $var, $value) = @_;
	
	if (defined $value) {
		$self->{'config'}->{$var} = $value;
	}
	
	return $self->get($var);
}


=head2 $config->clear($key)

Removes a given key from the configuration, returning its value.

=cut

sub clear {
	my ($self, $var) = @_;
	
	return delete $self->{'config'}->{$var};
}


=head2 $config->plugin($plugin)

Returns the configuration hashref for a given plugin name (not class).
Note that unlike the values from C<get()>, the plugin name is case
C<sensitive>.

=cut

sub plugin {
	my ($self, $plugin) = @_;
	
	return $self->{'config'}->{'plugin'}->{$plugin};
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

L<perl>, L<jebus>, L<Config::General>,
L<http://www.infobot.org/>, 

=cut

	

1;
__END__
	
	
