package JebusBot::Plugin::Factoid;
#
# $Id: Factoid.pm,v 1.8 2003/04/12 07:45:44 ctriv Exp $
#
# Stewie: Omnipotence... Yes.  Got to get me some of that. 
#
use JebusBot::Constants qw(:plugin);

use base 'JebusBot::Plugin';

use strict;
use warnings;

#
# This will live in a seperate file at some point...
#
my %langs = (
	English => {
		# 'is' and 'are' should be assigned to your verbs... for now only two verbs 
		# supported at a time.
		'is'		    => 'is',
		'are'			=> 'are',
		'verb'          => ['is', 'are'],
		'question_word' => ['where', 'what', 'who'],
		'determiner'    => ['a', 'an', 'the'],
		'dunno'         => [
			'I don\'t know', 'Wish I knew',
			q{I haven't a clue},
			'No idea', 'Bugger all, I dunno'
		],
		'welcomes'      => [
			'no problem', 'my pleasure', 
			'sure thing', 'no worries', 'de nada', 
			'de rien', 'bitte', 'pas de quoi'
		],
		'confused'      => [
			'huh?', 'what?', 'sorry...', 
			q{i'm not following you...},
			'excuse me?', 'qua?',
		],
		'hello'         => [
			'hello', 'hi', 'hey',
			'niihau', 'bonjour',
			'hola', 'salut', 'que tal',
			'privet', "what's up"
		],
		'ok'            => ['OK', 'okay'],
		'ok_nick'       => ['OK, [% nick %]', 'okay [% nick %]'],
		'no_remove'     => ['you have no access to remove factoids'],
		'no_change'     => ['you have no access to change factoids'],
		'no_i_wont'     => [q{No, I won't}],
		'silly'         => [q{Isn't that a bit silly}],
		
		'no_contain_X'  => [q{That doesn't contain '[% thing %]'}],
		'key_too_long'  => ['The key is too long (> [% max %] chars)'],
		'data_too_long' => [
			'That entry is too long, [% who %].',
			q{I'm sorry, but that entry is too long, [% who %].}
		],
		
		'forget'        => ['I forgot [% thing %]'],
		'donno_about'   => [
			q{I don't know about '[% thing %]'},
			q{I didn't have anything matching '[% thing %]'},
		],
		'exists'        => [
			'...but [% thing %] [% verb %] [% value %]...',
		], 
		'answer'        => [ # thing is bar
			'[% thing %] [% verb %] [% value %]',
			'i think [% thing %] [% verb %] [% value %]',
			'hmmm... [% thing %] [% verb %] [% value %]',
			'it has been said that [% thing %] [% verb %] [% value %]',
			'[% thing %] [% verb %] probably [% value %]',
			'rumour has it [% thing %] [% verb %] [% value %]',
			'i guess [% thing %] [% verb %] [% value %]',
			'well, [% thing %] [% verb %] [% value %]',
			'[% thing %] [% verb %], like, [% value %]'
		],
 	}
);

sub new {
	my ($class) = @_;
	
	my $lang = $JebusBot::Config->plugin('Factoid')->{'language'};
	
	$langs{$lang} || die "Unknown language: $lang\n";
	
	my $self = {
		lang            => $lang,
		is_private		=> 0,
		is_data         => JebusBot::Data->new("${class}_is"),
		are_data        => JebusBot::Data->new("${class}_are"),
		must_addr       => $JebusBot::Config->plugin('Factoid')->{'mustaddress'},
		max_key_size    => $JebusBot::Config->plugin('Factoid')->{'maxkeysize'}         || 64,
		max_data_size   => $JebusBot::Config->plugin('Factoid')->{'maxdatasize'}        || 500,
	};
	
	bless($self, $class);
	
	return $self;	
}


#
# Install our handler
#
sub irc_public { &handler; }
sub irc_msg    { 
	my ($self, $event) = @_;
	
	#
	# Note that things are private, because we don't do a CTCP action
	# in a private message.
	# 
	$event->{'is_private'}++;
	
	return $self->handler($event);	
}


#
# Take a top level look at the message, and figure out if we need to
# take action from it.
#  
sub handler {
	my ($self, $raw_event) = @_;
	
	my $event = $raw_event->filter($self->{'lang'});
	
	$self->statement_handler($event)
		or
	$self->question_handler($event);
	
	
	return NEXT;
}
				 
				 ######                        ######
				 ######   Question handling    ######
				 ######                        ######

#
# See if there is a question asked, and if there is handle it.
#
sub question_handler {
	my ($self, $event) = @_;
	
	my $msg = $event->msg;
		
	# stip the final question mark off the message, but remember if 
	# we did so.
	my $final_q_mark = $msg =~ s/\?+\s*$// ? 1 : 0;
	
	$msg =~ s/^\s+//;
	$msg =~ s/\s+$//;
	
	my $volunteer = 0;
	
	unless ($self->{'must_addr'}) {
		$volunteer += $final_q_mark;
	}
	
	$volunteer += $event->addressed;
	$volunteer += $event->{'is_private'} || 0;
	
	return unless $volunteer;
	
	my ($q_word, $thing, $verb);
	
	my $verb_regex     = $self->get_regex('verb');
	my $question_regex = $self->get_regex('question_word');
	
	if ($msg =~ /^\s*(.*?)\s+($verb_regex)\s+(.*?)\s*$/i) {
		($q_word, $verb, $thing) = ($1, $2, $3);
		
		my @tmp;
		my @q_words = $self->get_word_list('question_word');
		
		if (@tmp = grep { lc($_) eq $thing } @q_words) {
			# something like "foo is what" was sent - switch the order
			$thing  = $q_word;
			$q_word = $tmp[0];
		}
	}
	
	if (not $verb or not $q_word) {
		# something like "porn?"
		$thing = $msg;
	}
		
	$event->{'literal'} = $thing =~ s/^literal\s+//i ? 1 : 0;
			
	return $self->answer_question($event, $verb, $thing);
}


#
# look up the question, and send out our reply
#
sub answer_question {
	my ($self, $event, $verb, $thing) = @_;
	
	$JebusBot::Console->put("Factoid: answering: $thing");
	
	if ($verb) {
		$verb = lc $verb;
		
		if (my $ans = $self->{"${verb}_data"}->get($thing)) {
			return $self->format_answer($event, $ans, $verb);
		}
	}
	
	foreach $verb (qw(is are)) {
		if (my $ans = $self->{"${verb}_data"}->get($thing)) {
			return $self->format_answer($event, $ans, $verb);
		}
	}
	
	return $self->dunno_answer($event) if $event->addressed;
	
	return 1;
}

#
# These methods deal with printing our responses out
#
sub format_answer {	
	my ($self, $event, $row, $verb) = @_;
	
	my $msg  = $row->{'value'};
	my $who  = $event->nick;
	my $date = localtime;
	
	if ($event->{'literal'}) {
		$self->send("$who: $row->{'thing'} =$verb= $msg");
		return 1;
	}
		
	# handle the foo | bar messages
	if ($msg =~ m/\|/) {
		my @msgs = split(m/\s*\|\s*/, $msg);
		
		$msg = @msgs[rand @msgs];
	}
	
	
	$msg =~ s/(?<!\\)\$who/$who/g;
	$msg =~ s/(?<!\\)\$date/$date/g;
	
	if ($msg =~ s/^<reply>\s*//i) {
		$self->send($msg);
		return 1;
	}
	
	# we don't do CTCP action to private messges.
	if (!$event->{'is_private'} and $msg =~ s/^<action>\s*//i) {
		$self->action($msg);
		return 1;
	}
	
	my $ans = $self->get_and_fill_random(answer => {
		thing => $row->{'thing'},
		value => $msg,
		verb  => $verb,
	});
			
	if ($ans =~ s/^\Q$who\E is/you are/i) { # fix the person
		# do nothing
	} else {
		my $me = CORE::join('|', JebusBot::bot_names());

		$ans =~ s/^(?:$me) is /i am /ig;
		$ans =~ s/ (?:$me) is / i am /ig;
		$ans =~ s/^(?:$me) was /i was /ig;
		$ans =~ s/ (?:$me) was / i was /ig;

		$ans =~ s/^you are (\.*)/i am $1/ig;
		$ans =~ s/ you are (\.*)/ i am $1/ig;
		
		$ans =~ s/ (?:$me)\'?s / my /ig;
	}
		
	$self->send($ans);
	
	return 1;
}

sub dunno_answer {
	my ($self, $event, $thing) = @_;
	
	my $ans = $self->get_random('dunno');
	
	$ans .= ', ' . $event->nick;
	
	$self->send($ans);
	
	return 1;
}
		
	
				 ######                         ######
				 ######   Statement handling    ######
				 ######                         ######
	
sub statement_handler {
	my ($self, $event) = @_;
	
	return if $self->{'must_addr'} and !$self->addressed;
	
	my $msg = $event->msg;
	my $me  = CORE::join('|', JebusBot::bot_names());
		
	if ($msg =~ s/^no,?\s+(:?(?:$me),?\s+)?//i) {
		$event->{'correction'}++;
	}
	
	if ($msg =~ s/^forget\s+(:?(:?a|an|the)\s+)?//i) {
		$event->msg($msg);
		return $self->delete_factoid($event);
	}
	
	if ($event->addressed and $msg =~  m|^
										 \s*(.*?)
										 \s+=~\s+
										 s\/(.+?)\/(.*?)\/[a-z]*;?
										 \s*$|x )
	{
		return $self->twiddle_factoid($event, $1, $2, $3);
	}
	
	
	my $verb_regex     = $self->get_regex('verb');
	my $question_regex = $self->get_regex('question_word');
	
	if ($msg =~ /(.*?)\s+(?<!\\)($verb_regex)\s+(.*)/i) {
		my ($thing, $verb, $value) = (lc $1, lc $2, $3);
		
		$thing =~ s/^\s*(?:the|da|an?)\s+//i; # discard article
	    $thing =~ s/^\s*(.*?)\s*$/$1/;
	    $verb  =~ s/^\s*(.*?)\s*$/$1/;
	    $value =~ s/^\s*(.*?)\s*$/$1/;
		
		if (length($thing) > $self->{'max_key_size'}) {
			if ($event->addressed) {
				$self->send(
					$self->get_and_fill_random(key_too_long => { max => $self->{'max_key_size'}})
				);
			}
			return;
		}
		
		if (length($value) > $self->{'max_data_size'}) {
			if ($event->addressed) {
				$self->send(
					$self->get_and_fill_random(data_too_long => { nick => $event->nick })
				)
			}
			return;
		}
		
		# ignore questions ("Who is", "What are" ...)
		$thing =~ m/^(?:who|what|when|where|why|how)$/ and return;
		
		# Some things we don't pay attention to if we aren't directly addressed
		unless ($event->addressed) {
			$thing =~ m/^(?:who|what|when|where|why|how|it) /i and return;
			$thing =~ m/^(?:this|that|these|those|they|you) /i and return;
			$thing =~ m/^(?:every(one|body)|we) /i             and return;

			$thing =~ m/^\s*\*/                                and return; # server message
			$thing =~ m/^\s*<+[-=]+/                           and return; # <--- arrows
			$thing =~ m/^[\[<\(]\w+[\]>\)]/                    and return; # [nick] from bots
			$thing =~ m/^heya?,? /                             and return; # greetings
			$thing =~ m/^\s*th(?:is|at|ere|ese|ose|ey)/i       and return; # contextless
			$thing =~ m/^\s*it\'?s?\W/i                        and return; # contextless clitic
			$thing =~ m/^\s*if /i                              and return; # hypothetical
			$thing =~ m/^\s*how\W/i                            and return; # too much trouble for now
			$thing =~ m/^\s*why\W/i                            and return; # too much trouble for now
			$thing =~ m/^\s*h(?:is|er) /i                      and return; # her name is
			$thing =~ m/^\s*\D[\d\w]*\.{2,}/                   and return; # x...
			$thing =~ m/^\s*so is/i                            and return; # so is (no referent)
			$thing =~ m/^\s*s+o+r+[ye]+\b/i                    and return; # sorry
			$thing =~ m/^\s*supposedly/i                       and return;
			$thing =~ m/^all /                                 and return; # all you have to do, all you guys...
		}
			
		$thing =~ s/\#(\S+)\#/$1/g;
		$thing =~ s/\?+\s*$//; # strip the ? off the key
		
        $value =~ s/\#\|\#/\\\|/g;
	    $value =~ s/\#(\S+)\#/$1/g;
	    
	    if ($value =~ s/^\s*also\s*//) {
	    	return $self->append_factoid($event, $thing, $verb, $value);
	    }

	    $self->update_factoid($event, $thing, $verb, $value);
		
		return 1;
	}
	
	return;
}


sub update_factoid {
	my ($self, $event, $thing, $verb, $value) = @_;
	
	my $data = $self->{"${verb}_data"};
	
	my $exists = $data->exists($thing);
	
	if ($exists and !$event->{'correction'}) {			
		if ($event->addressed)  {
			$JebusBot::Console->put("Factoid: $thing exists");
			$self->send(
				$self->get_and_fill_random(exists => {
					 thing => $thing,
					 verb  => $verb,
					 value => $value,
				})
			);
		}
	} else {
		if ($exists) { # we're doing a correction
			$JebusBot::Console->put("Factoid: Updating $thing to $value");
			$data->update($thing => { value => $value });
		} else {
			$JebusBot::Console->put("Factoid: Inserting $thing =$verb=> $value");
			$data->insert($thing => { value => $value });
		}
		
		if ($event->addressed || $exists) {
			$self->send($self->get_and_fill_random(ok_nick => { nick => $event->nick }));
		}
	}
}

sub append_factoid {
	my ($self, $event, $thing, $verb, $new_value) = @_;
	
	$JebusBot::Console->put("Factoid: Appending $new_value to $thing");
	
	my $data = $self->{"${verb}_data"};
	
	my $row = $data->get($thing);
		
	unless ($row) {
		if ($event->addressed) {
			$self->send($self->get_and_fill_random(donno_about => { thing => $thing }));
		}
		return 1;
	}
	
	$row->{'value'} .= " or $new_value";
	
	if (length($row->{'value'}) > $self->{'max_data_size'}) {
		if ($event->addressed) {
			$self->send(
				$self->get_and_fill_random(data_too_long => { nick => $event->nick })
			);
		}
		return;
	}
	
	$data->update($thing => $row);
	
	if ($event->addressed) {
		$self->send($self->get_and_fill_random(ok_nick => { nick => $event->nick }));
	}
		
	return 1;
}


sub twiddle_factoid {
	my ($self, $event, $thing, $oldpiece, $newpiece) = @_;
	
	my $verb;
	my $row;
	for (qw(is are)) {
		if ($row = $self->{"${_}_data"}->get($thing)) {
			$verb = $_;
			last;
		}
	}
	
	unless ($row) {
		$self->send($self->get_and_fill_random(donno_about => { thing => $thing }));
		return 1;
	}
	
	$JebusBot::Console->put("Factoid: Modifying $thing (s/$newpiece/$oldpiece/)");
	
	$row->{'value'} =~ s/\Q$oldpiece\E/$newpiece/;
	
	$self->{"${verb}_data"}->update($thing => $row);
	
	$self->send($self->get_and_fill_random(ok_nick => { nick => $event->nick }));
	
	return 1;
}
	

sub delete_factoid {
	my ($self, $event) = @_;
	
	my $thing = lc $event->msg;
		
	$thing =~ s/\s*$//;
	
	$JebusBot::Console->put("Factoid: Deleting $thing");
	
	if ($self->{"is_data"}->delete($thing) == 0)  {
		if ($self->{"are_data"}->delete($thing) == 0) {
			$self->send($self->get_and_fill_random(donno_about => { thing => $thing }));
			return 1;
		}
	}
		
	$self->send($self->get_and_fill_random(forget => { thing => $thing }));
	
	return 1;
}	
	
#################################################################################	
#
# Languaage utility methods
#	 
sub get_regex {
	my ($self, $key) = @_;
	
	return unless my $bits = $langs{$self->{'lang'}}->{$key};
	
	my $pat = join('|', @$bits);
	
	return qr/$pat/;
}
 
 
sub get_word_list {
	my ($self, $key) = @_;
	
	return unless my $list = $langs{$self->{'lang'}}->{$key};
	
	return @$list;
}

sub get_random {
	my ($self, $key) = @_;
	
	return unless my $list = $langs{$self->{'lang'}}->{$key};

	return $list->[rand @$list];
}


sub get_and_fill_random {
	my ($self, $key, $params) = @_;
	
	my $string = $self->get_random($key);
	
	unless ($string) {
		return "UNKNOWN LANG KEY: $key";
	}
	
	$string =~ s{\[%\s*(\w+)\s*%\]}
				{ $params->{$1} || '' }ge;
				
	return $string;
}
				
				


#
# Set up our data stores.
#
package JebusBot::Plugin::Factoid_is;
use base 'JebusBot::Plugin';

__PACKAGE__->data_attributes({
 	thing       => 'varchar(64)',
 	value       => 'blob',
 	primary_key => 'thing',
 });

package JebusBot::Plugin::Factoid_are;
use base 'JebusBot::Plugin';

__PACKAGE__->data_attributes({
 	thing       => 'varchar(64)',
 	value       => 'blob',
 	primary_key => 'thing',
 });
  
1; 
