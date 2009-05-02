package JebusBot::Filter::English;
#
# Stewie (talking about Peter):
#     Oh my God!  It's finally happened.  He's become so massive he collapsed 
#     into himself, like a neutron star! 
# 
use base 'JebusBot::Filter';

use strict;
use warnings;

#
# Lots of this was shamlessly stolen from infobot.
#

sub filter {
	my ($class, $event) = @_;

	normalize_query($event);
	switch_person($event);
	
	return $event;
}

sub normalize_query {
    my ($event) = @_;

    my $in = $event->msg;
    my $o_in = $in;
    
    $in = " $in ";
    
    # where's -> where is
    $in =~ s/^ wh(at|ere|o)'s / wh$1 is /i;
    $in =~ s/^ wh(at|ere|o)'re / wh$1 are /i;
    
    # where blah is -> where is blah
    $in =~ s/ (where|what|who)\s+(\S+)\s+(is|are) / $1 $3 $2 /i;
    
    # where blah is -> where is blah
    $in =~ s/ (where|what|who)\s+(.*)\s+(is|are) / $1 $3 $2 /i;
    
    $in =~ s/^\s*(.*?)\s*/$1/;
    
    $in =~ s/be tellin\'?g?/tell/i;
    $in =~ s/ \'?bout/ about/i;
    
    $in =~ s/,? any(hoo?w?|ways?)/ /ig;
    $in =~ s/,?\s*(pretty )*please\??\s*$/\?/i;
    
    # what country is ...
    if ($in =~ 	s/wh(at|ich)\s+(add?res?s|country|place|net (suffix|domain))/wh$1 /ig) {
		if ((length($in) == 2) && ($in !~ /^\./)) {
		    $in = '.'.$in;
		}	
		$in .= '?';
    }
    
    # profanity filters.  just delete it
    $in =~ s/th(e|at|is) (((m(o|u)th(a|er) ?)?fuck(in\'?g?)?|hell|heck|(god-?)?damn?(ed)?) ?)+//ig;
    
    $in =~ s/wtf/where/gi; 
    $in =~ s/this (.*) thingy?/ $1/gi;
    $in =~ s/this thingy? (called )?//gi;
    $in =~ s/ha(s|ve) (an?y?|some|ne) (idea|clue|guess|seen) /know /ig;
    $in =~ s/does (any|ne|some) ?(1|one|body) know //ig;
    $in =~ s/do you know //ig;
    $in =~ s/can (you|u|((any|ne|some) ?(1|one|body)))( please)? tell (me|us|him|her)//ig;
    $in =~ s/where (\S+) can \S+ (a|an|the)?//ig;
    $in =~ s/(can|do) (i|you|one|we|he|she) (find|get)( this)?/is/i; # where can i find
    $in =~ s/(i|one|we|he|she) can (find|get)/is/gi; # where i can find
    $in =~ s/(the )?(address|url) (for|to) //i; # this should be more specific
    $in =~ s/(where is )+/where is /ig;
    $in =~ s/\s+/ /g;
    $in =~ s/^\s+//;
    
    #	$in =~ s/\b(the|an?)\s+/ /i; # handle first article in query
    $in =~ s/\s+/ /g;
    
	$in =~ s/^\s+//;
	$in =~ s/\s+$//;
    
    $event->msg($in) if $in ne $o_in;
}

sub switch_person {
	my ($event) = @_;
	
	my $in   = $event->msg;
	my $o_in = $in;
	
	
	my $who     = $event->nick;	
	my $safeWho = purify_nick($who);
	
	# $safeWho will cause trouble in nicks with deleted \W's
	$in =~ s/(^|\W)${safeWho}s\s+/$1${who}\'s /ig; # fix genitives
	$in =~ s/(^|\W)${safeWho}s$/$1${who}\'s/ig; # fix genitives
	$in =~ s/(^|\W)${safeWho}\'(\s|$)/$1${who}\'s$2/ig; # fix genitives
	
	$in =~ s/(^|\s)i\'m(\W|$)/$1$who is$2/ig;
	$in =~ s/(^|\s)i\'ve(\W|$)/$1$who has$2/ig;
	$in =~ s/(^|\s)i have(\W|$)/$1$who has$2/ig;
	$in =~ s/(^|\s)i haven\'?t(\W|$)/$1$who has not$2/ig;
	$in =~ s/(^|\s)i(\W|$)/$1$who$2/ig;
	$in =~ s/ am\b/ is/i;
	$in =~ s/\bam /is/i;
	$in =~ s/(^|\s)(me|myself)(\W|$)/$1$who$3/ig;
	$in =~ s/(^|\s)my(\W|$)/$1${who}\'s$2/ig; # turn 'my' into name's
	$in =~ s/(^|\W)you\'?re(\W|$)/$1you are$2/ig;
			
	if ($event->addressed) {
		my $id = $JebusBot::Config->get('nick');
		$in =~ s/yourself/$id/i;
		$in =~ s/(^|\W)are you(\W|$)/$1is $id$2/ig;
		$in =~ s/(^|\W)you are(\W|$)/$1$id is$2/ig;
		$in =~ s/(^|\W)you(\W|$)/$1$id$2/ig; 
		$in =~ s/(^|\W)your(\W|$)/$1$id\'s$2/ig;
	}
	
	$event->msg($in) if $o_in ne $in;   
}


sub purify_nick {
    my ($safeWho) = @_;

    $safeWho =~ s/\*//g;
    $safeWho =~ s/\\/\\\\/g;
    $safeWho =~ s/\[/\\\[/g;
    $safeWho =~ s/\]/\\\]/g;
    $safeWho =~ s/\|/\\\|/g;
    $safeWho =~ tr/A-Z/a-z/;
    $safeWho = substr($safeWho, 0, 9);
    $safeWho =~ s/\s+.*//;
    
    return $safeWho;
}


1;

