package JebusBot::Data;
#
# $Id: Data.pm,v 1.6 2003/05/19 20:28:13 ctriv Exp $
#
#
# Stewie: I never knew biscuit as a dog but I knew her as a table. Steady, all four 
#         legs the same length. 
# Brian:  That's enough. 
# Stewie: Oh yes terra pax requiem and so forth. 
#

=head1 NAME

JebusBot::Data - Jebus Remember!

=head1 SYNOPSIS

 my $data = JebusBot::Data->new($plungin_class);
 
 $data->store(stuff => { foo => 'bar' });
 
 my $stuff = $data->get($stuff);  # $stuff = { foo => bar }

=head1 DESCRIPTION

Jebus can use several methods for storing it's data.  The default is for it to use
a DB file database, but it can also use SQL databases.  Support is currently in place
for SQLite and MySQL.

=cut

use strict;
use warnings;

use Storable ();

sub create_pluginfo {
	my ($class, $plugin, $data) = @_;
	
	my $real_class = $class->_get_subclass;
	
	$plugin = $class->_plugin_name($plugin);
	
	if (my $meth = $real_class->can('create_pluginfo')) {
		return $meth->($real_class, $plugin, $data);
	}
}

=head2 JebusBot::Data->new($plugin_class)

Returns a data store object for a given plugin class

=cut

sub new {
	my ($class, $plugin) = @_;
	
	my $pluginclass = ref $plugin || $plugin;
	
	my $self = {
		plugin      => $class->_plugin_name($pluginclass),
		autocommit  => 1,
		changes     => {},
	};
	
	bless($self, $class);
	
	return $self;
}



=head2 $data->get($key)

Returns a record for a given key.  If you've set your plugin's
data attributes, then the record will conform to that specification.
Otherwise the record is what ever you stored.

=head2 $data->store($key => \%record)

Update the given record.  If you've set a scheme, and it doesn't
match the record, then C<die> will be called.  Store may have to do a
check if it has to update or insert, so use update and insert directly 
if you can.

=head2 $data->insert($key => \%record)

Update the given record.  If you've set a scheme, and it doesn't
match the record, then C<die> will be called.

=head2 $data->update($key => \%record)

Update the given record.  If you've set a scheme, and it doesn't
match the record, then C<die> will be called.

=head2 $data->delete($key)

Removes the record for key from the data store.

=head2 $data->exists($key)

Returns boolean, does C<$key> exist in the data store?

=head2 $data->autocommit(1/0)

JebusBot::Data has the option of doing software level transactions.  This
is mainly for performance reasons, as storing can be intensive in certain
situations.  By default all stores are commited automatically, but this can
be turned off with this method.

UNIMPLEMENTED

=cut

sub autocommit {
	my ($self, $flag) = @_;
	
	if (defined $flag) { 
		$self->{'autocommit'} = $flag;
	}
	
	return $self->{'autocommit'};
}

=head2 $data->commit

Commits any changes to the data store.

=head2 $data->freeze($ref)

Freezes the ref into a string'ish thing.

=head2 $data->thaw($string)

Unfreezes something you frooze

=cut

sub freeze {
	my ($self, $thing) = @_;
	
	return Storable::nfreeze($thing);
}

sub thaw {
	my ($self, $string) = @_;
	
	return Storable::thaw($string);
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

L<perl>, L<jebus>, L<DBI>, L<http://www.mysql.com/>, L<http://www.sqlite.org/>,
L<http://www.infobot.org/>, 

=cut


#
# Utility functions
#

sub _plugin_name {
	my ($class, $pluginclass) = @_;
	
	$pluginclass =~ s/^.*:://;
	
	return lc $pluginclass;
}

1;
__END__
