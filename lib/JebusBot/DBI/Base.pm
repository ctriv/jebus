package JebusBot::DBI::Base;
#
# $Id: DBI.pm,v 1.6 2003/04/10 16:50:13 ctriv Exp $
#
# Peter:    I'm gonna go microwave a bagel and have sex with it. 
# Quagmire: Butter's in the fridge 
#

use strict;
use warnings;

use base 'Ima::DBI';

sub init {
	my ($class, $config) = @_;
	
	$class->set_db('Main', $class->_dsn, $config->{'dbuser'}, $config->{'dbpass'},
						{ RaiseError => 1, AutoCommit => 1 });
}



1;
