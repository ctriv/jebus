# $Id: Makefile.PL,v 1.2 2003/05/19 20:09:14 ctriv Exp $

use ExtUtils::MakeMaker qw(WriteMakefile);

die <<AMEN if $] < 5.006;

Jebus requires perl 5.6.0 or greater.

AMEN

WriteMakefile(
	'NAME'			=> 'JebusBot',
	'VERSION_FROM'	=> 'lib/JebusBot.pm',
	'PL_FILES'      => {'bin/jebusbot.PL' => 'bin/jebusbot'},
	'PREREQ_PM'		=> {
		POE::Component::IRC::Object		=> 0,
		POE::Component::Client::HTTP 	=> 0,
		Term::ANSIColor		       	 	=> 0,
		Storable         				=> 0,
		Time::Duration					=> 0,
		XML::RSS						=> 0,
		DBI								=> 0,
		Config::General                 => 0,
	},
   ($] >= 5.005 ?    
	('AUTHOR'		=> 'Chris Reinhardt <perl@triv.org>',
	'ABSTRACT'		=> 'IRC Robot', ) : ()),
	
	
	'clean'			=> { FILES => 'bin/jebusbot' },
);
