package JebusBot::Data::DBI::MySQL;
#
# $Id: MySQL.pm,v 1.3 2003/04/08 10:05:59 ctriv Exp $
#
# Stewie: Blast you and your estragenical tyranny!! 
#

use strict;
use warnings;

use DBD::mysql;

use base 'JebusBot::Data::DBI';

sub _dsn {
	my ($class, $config) = @_;
	
	for (qw(dbname dbuser dbpass)) {
		unless ($config->{$_}) {
			die "Configuration Error: $_ not given for data store";
		}
	}
	
	my $dsn = "DBI:mysql:database=$config->{'dbname'}";
	
	if ($config->{'dbhost'}) {
		$dsn .= ";host=$config->{'dbhost'}";
	}
	
	if ($config->{'dbport'}) {
		$dsn .= ";port=$config->{'dbport'}";
	}
	
	return $dsn;
}

sub create_pluginfo {
	my ($class, $name, $attr) = @_;
	
	my $primary_key = delete $attr->{'primary_key'}
						|| die "No primary key given for $class.\n";

	$JebusBot::Data::DBI::Keys{$name} = $primary_key;						
						
	my $indexs		= delete $attr->{'index'};
	
	my $statement = "CREATE TABLE IF NOT EXISTS pluginfo_$name (";
	
	my @columns;
	
	while (my($k, $v) = each %$attr) {
		my $col = "$k $v";
		
		if ($primary_key eq $k) {
			$col .= " PRIMARY KEY"
		}
		
		push(@columns, $col);
	}
	
	foreach my $index (@$indexs) {
		push(@columns, "INDEX ($index)");
	}
	
	$statement .= join(', ' => @columns) . ");";
		
	$class->dbh->do($statement);
	
	$JebusBot::Data::DBI::Special{$name} = 1;
}
	
=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 Chris Reinhardt

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

=cut			

1; 

__END__
