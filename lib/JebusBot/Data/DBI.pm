package JebusBot::Data::DBI;
#
# $Id: DBI.pm,v 1.6 2003/04/10 16:50:13 ctriv Exp $
#
# (stewie rings three different bells, 3 servents apear) 
#
# You! fetch me the Wall Street Journal. You two! Fight to the death! 
#
use strict;
use warnings;

use DBI;

use base 'JebusBot::Data';

our %Special;
our %Keys;

my $DBH;

#
# Set up our handle (at some point in the future we'll add tests
# to see if it's gone away
#
sub _init {
	my ($class) = @_;
	
	my $config = (values %{$JebusBot::Config->get('datastore')})[0];
	
	my $dsn = $class->_dsn($config);
	
	$DBH ||= DBI->connect($dsn, $config->{'dbuser'}, $config->{'dbpass'},
						{ RaiseError => 1, AutoCommit => 1 });
}

#
# Global DBH (this might change)
#
sub dbh   { $DBH }

#
# convience subs
#
sub quote      { $_[0]->dbh->quote($_[1]);    }
sub is_special { $Special{$_[0]->{'plugin'}}; }
sub key_column { $Keys{$_[0]->{'plugin'}};    }

sub table { 
	my ($self) = @_;
	
	if ($self->is_special) {
		return "pluginfo_$self->{'plugin'}";
	} else {
		return "pluginfo";
	}
}

sub where_clause {
	my ($self) = @_;
	
	if ($self->is_special) {
		my $key_col = $self->key_column;
		return "$key_col=?";
	} else {
		return "plugin=? AND name=?"
	}
}

#
# we might use this for caching in the future
#
sub prepare {
	my ($self, $statement) = @_;
	
	if (0 && $JebusBot::Config->get('debug')) {
		print STDERR ref($self) || $self, qq{ "$statement"\n};
	}
	
	return $self->dbh->prepare($statement);
}

#
# the DBI get implementation
#
sub get {
	my ($self, $key) = @_;
	
	if ($self->is_special) {
		my $table   = $self->table;
		my $key_col = $self->key_column;
				
		return $self->fetchrow_hashref("SELECT * FROM $table WHERE $key_col=?", $key);
	} else {
		return $self->fetch_record($key);
	}
}

sub fetchrow_hashref {
	my ($self, $statement, @args) = @_;
		
	my $sth = $self->prepare($statement);
	
	$sth->execute(@args);
	
	my $tmp = $sth->fetchrow_hashref;
	
	$sth->finish;
	
	return $tmp;
}

sub fetch_record {
	my ($self, $key) = @_;
	my $frozen_record;
	
	my $sth = $self->prepare("SELECT data FROM pluginfo WHERE plugin=? and name=?");
	
	$sth->execute($self->{'plugin'}, $key);
	$sth->bind_columns(\$frozen_record);
	$sth->fetch;
	$sth->finish;
	
	return $self->thaw($frozen_record);
}

#
# Store 
#
sub store {
	my ($self, $key, $record) = @_;
	
	_check_hash($record);
	
	if ($self->exists($key)) {
		$self->update($key => $record);
	} else {
		$self->insert($key => $record);
	}
}
	

#
# Insert
#
sub insert {
	my ($self, $key, $rec) = @_;
	
	if ($self->is_special) {
		$rec->{$self->key_column} = $key;
		$self->insert_hashref($rec);
	} else {
		$self->insert_record($key => $rec);
	}
}


sub insert_hashref {
	my ($self, $insert) = @_;

	
	my $table     = $self->table;
	my $statement = "INSERT INTO $table (";
	
	my @columns = keys   %$insert;
	my @data    = values %$insert;

	$statement .= join(',' => @columns);
	$statement .= ') VALUES (';
	
	my $entries = $#columns - 1;
	for (0..$entries) {
		$statement .= '?,';
	}
	$statement .= '?)';
	
	my $sth = $self->prepare($statement);
	$sth->execute(@data);
	$sth->finish;
	
	return 1;
}

sub insert_record {
	my ($self, $key, $rec) = @_;
	
	my $string = $self->freeze($rec);
	
	$self->insert_hashref({
		name   => $key, 
		plugin => $self->{'plugin'},
		data   => $string,
	});
}

#
# Update
#
sub update {
	my ($self, $key, $rec) = @_;
	
	if ($self->is_special) {
		my $key_col = $self->key_column;
		$self->update_hashref($rec, $key);
	} else {
		$self->update_record($key, $rec);
	}
}

sub update_hashref {
	my ($self, $update, @args) = @_;
	
	my $where = $self->where_clause;
	my $table = $self->table;

	my $statement = "UPDATE $table SET ";

	my @columns = keys   %$update;
	my @data    = values %$update;

	$statement .= join('=?,' => @columns);
	
	$statement .= "=? WHERE $where";
	
	my $sth = $self->prepare($statement);
	
	$sth->execute(@data, @args);
	$sth->finish;
	
	return 1;
}

sub update_record {
	my ($self, $key, $record) = @_;
	
	my $string = $self->freeze($record);
	my $table  = $self->table;
	my $sth = $self->prepare("UPDATE $table SET data=? WHERE plugin='$self->{'plugin'}' and name=?");
	
	$sth->execute($string, $key);
	
	$sth->finish;
}


#
# Delete
#
sub delete {
	my ($self, $key) = @_;
	
	my $table = $self->table;
	my $where = $self->where_clause;
	my $sth = $self->prepare("DELETE FROM $table WHERE $where");

	my $rows_deleted;

	if ($self->is_special) {
		$rows_deleted = $sth->execute($key);
	} else {
		$rows_deleted = $sth->execute($self->{'plugin'}, $key);
	}
	
	return $rows_deleted;
}
		
	
	


#
# Exists
#
sub exists {
	my ($self, $key) = @_;
	
	if ($self->is_special) {
		return $self->_rows($self->table, $self->where_clause, $key);
	} else {
		return $self->_rows($self->table, $self->where_clause, $self->{'plugin'}, $key);
	}
}
		

sub _rows {
	my ($self, $table, $where, @args) = @_;

	my $statement = "SELECT COUNT(*) FROM $table WHERE $where";
	my $rows;
	
	my $sth = $self->prepare($statement);
	
	$sth->execute(@args);
	$sth->bind_columns(\$rows);
	$sth->fetch;
	$sth->finish;
	
	return $rows;
}

	
sub _check_hash {
	UNIVERSAL::isa($_[0], 'HASH') or
		die "Records must be hashrefs.";
}

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 Chris Reinhardt

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

THIS PACKAGE IS PROVIDED WITH USEFULNESS IN MIND, BUT WITHOUT GUARANTEE
OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. USE IT AT YOUR
OWN RISK.

=cut

1;
__END__
