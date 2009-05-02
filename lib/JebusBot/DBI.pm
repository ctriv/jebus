package JebusBot::DBI;
#
# $Id: DBI.pm,v 1.6 2003/04/10 16:50:13 ctriv Exp $
#
# (stewie rings three different bells, 3 servents apear) 
#
# You! fetch me the Wall Street Journal. You two! Fight to the death! 
#
use strict;
use warnings;

our @ISA;

my %subclasses = (
 	mysql  => 'MySQL',
	sqlite => 'SQLite',
);

sub init {
	my $config = $JebusBot::Config->get('datastore');
	
	if (scalar(keys %$config) > 1) {
		die "Configuration Error: More than one DataStore parameter set.\n";
	}
	
	my $type = lc((keys %$config)[0]);
	$config  = (values %$config)[0];
	
	
	@ISA = (__PACKAGE__ . $subclasses{$type});
	
	__PACKAGE__->SUPER::init($config);
}

1;

__END__
