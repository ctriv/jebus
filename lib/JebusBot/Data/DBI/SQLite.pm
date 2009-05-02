package JebusBot::Data::DBI::SQLite;
#
# $Id: SQLite.pm,v 1.2 2003/04/08 10:05:59 ctriv Exp $
#
# Lois: Sweetie, it's broccoli.  It's good for you.  Now open up for the 
#       airplane. (makes airplane noise) 
# Stewie: Never! Damn the broccoli, damn you, and damn the Wright Brothers! 
#

use strict;
use warnings;

use DBD::SQLite;

use base 'JebusBot::Data::DBI';

sub _dsn {
	my ($class, $config) = @_;
	
	my $file = JebusBot::bot_root_relative($config->{'dbfile'});
	
	return "DBI:SQLite:dbname=$file";
}

sub create_pluginfo {
	my ($class, $name, $attr) = @_;
	
	my $table = "pluginfo_$name";
	
	my $primary_key = delete $attr->{'primary_key'}
						|| die "No primary key given for $class.\n";

	$JebusBot::Data::DBI::Keys{$name} = $primary_key;	
	
	# What a hack!
	eval { $class->dbh->do("SELECT 1 from $table") };
		
	if ($@) {				
		my $indexs		= delete $attr->{'index'};
		
		my $statement = "CREATE TABLE pluginfo_$name (";
		
		my @columns;
		
		while (my($k, $v) = each %$attr) {
			my $col = "$k $v";
			
			if ($primary_key eq $k) {
				$col .= " PRIMARY KEY"
			}
			
			push(@columns, $col);
		}
		
		$statement .= join(', ' => @columns) . ")";
			
		$class->dbh->do($statement);
		
		foreach my $index (@$indexs) {
			$class->dbh->do("CREATE INDEX ${index}_index ON pluginfo_$name ($index)");
		}
	}
	
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
