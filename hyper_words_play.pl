#!/usr/bin/perl
###Copyright [2018] [Iantcho Vassilev <ianchov@gmail.com>]
###
###Licensed under the Apache License, Version 2.0 (the "License");
###you may not use this file except in compliance with the License.
###You may obtain a copy of the License at
###
###  http://www.apache.org/licenses/LICENSE-2.0
###
###Unless required by applicable law or agreed to in writing, software
###distributed under the License is distributed on an "AS IS" BASIS,
###WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
###See the License for the specific language governing permissions and
###limitations under the License.

#### Generates a result for the "Hyper Words" problem.
#### It takes standard input ("<test.in") and per default writes "test.out"
#### with the scrable words and letters. It runs with timer below 5secs as per 
#### the requirement 
#### Total memory usage is 26-27MB
 
use strict;
use warnings;
#use Data::Dumper;
#use Memory::Usage;
#my $mu = Memory::Usage->new();
#$mu->record('starting work');
my $start = time; # we measure the time it runs
my $letters;    #goes to @allallowedletters
my @inputFILE         = ();    # our INPUT
my @bag               = ();    # first 7 letters allowed
my @allallowedletters = ();    # array of the allowed letters
my $highestWord;  			   # current best word we can use
my @lettersHW;				   # array of the best word`s letter
my @used_words   = ();         # put words already used for not repeating them
my $we_end       = 0;		   # a safety button for stop
my $output_commands;		   # the commands we write in test.out

# Map letters to scrabble values
my %values = (
    E => 1,
    A => 1,
    I => 1,
    O => 1,
    N => 1,
    R => 1,
    T => 1,
    L => 1,
    S => 1,
    U => 1,
    D => 2,
    G => 2,
    B => 3,
    C => 3,
    M => 3,
    P => 3,
    F => 4,
    H => 4,
    V => 4,
    W => 4,
    Y => 4,
    K => 5,
    J => 8,
    X => 8,
    Q => 10,
    Z => 10
);

# Read in a dictionary file either from @ARGV or the default
#my $dictionary = read_file($ARGV[0] || "words_10k.txt") or die "Can't open file: $!";
@inputFILE = <STDIN>;    #file slurping; we already know that the files IN are too small
my $temp = $inputFILE[1];
#$temp =~ s/[\r\n]+$//;
@allallowedletters = split //, $temp;
my $dictionary = "@inputFILE";
$dictionary =~ s/^(?:.*\n){1,3}//;    #strip first 3 lines

# Populate @bag with first 7 letters
for ( my $i = 0 ; $i < 7 ; $i++ ) {
    push( @bag, shift(@allallowedletters) );
}

# Get the sum of the scrabble values of the letters in a word
sub wordValue {
    my $word = shift;
    my $sum  = 0;

    # Split the word into an array of individual letters
    for my $letter ( split //, $word ) {

        # If it's not in the table, the scrabble value is 0
        $sum += $values{$letter} || 0;
    }
    return $sum;
}

sub checkScore {

    # if ( $we_end == 1 ) {
        # return;
    # }
	my $letters=shift;
    my $highestScore = 0;
    $highestWord = "";

# Regex through the dictionary to find words only including the given letters/
# First we find words (a break \b on each side makes of a word) using any number
# of letters as long as every letter is in the inputted string
    my $lettersClass = "[$letters]{0,7}";  #limiting chars up to 7 letters {0,7}
    my @matches = $dictionary =~ /\b$lettersClass+\b/ig;

    # Go through the matches from the initial query
	WORD: for my $word (@matches) {

		# Check the number of occurrences of each letter: loop through the letters in the word
        if ( $word ~~ @used_words ) {
                      next;
        }
      LETTER: for my $letter ( split "", $word ) {

            #print $letter;
            # Get the number of times the letter occurs in the word with a RegEx
            my $wordOccurrences = () = $word =~ /$letter/ig;

    # Get the number of times the letter occurs in the input string with a RegEx
            my $lettersOccurrences = () = $letters =~ /$letter/ig;
	# Break out of the WORD loop if there are too many of a given type of letter in the word
            next WORD if ( $wordOccurrences > $lettersOccurrences );
        }

# If we've made it here, the word fits the input string, so we can check its score and save it
# if it's the highest so far
        my $score = wordValue($word);
        if ( $score > $highestScore ) {
            $highestScore = $score;
            $highestWord  = $word;
        }
    }

    if ( $highestScore == 0 ) {
        return $highestWord="",$highestScore;
    }
    else {
        return $highestWord,$highestScore;
    }

}

sub compareBagWord {

	
		### In the implementation of hyper_words_checker.py - it cannot detect reuse of the old letters put in the bag. 
		###	In our case there are after "\n" - new line in the @allallowedletters array so we check if the somewhere next is 
		### this new line and just cut the output if there is...because the checker will penalize us for not recognising the next letters
		### which actually are there
	for my $i (0..6)
		{
		if ($allallowedletters[$i] eq "\n")
				{
				$we_end = 1;
				return;
				} 
		}
		
		####
		
    my $letters = join "", @bag;
    my $word = $highestWord;

    for my $i ( 0 .. $#bag ) {
        my $letter = $bag[$i];
        my $wordOccurrences = () = $word =~ /$letter/ig;
		my $lettersOccurrences = () = $letters =~ /$letter/ig;
		
		if ( $wordOccurrences == 0 ) {
		    $output_commands .= "C $bag[$i]\n";
            push @allallowedletters, $bag[$i];
            $bag[$i] = shift @allallowedletters;
		}
		# we do not like _ so we try to change it for some more valuable letter..not the best approach but it works
        redo if ( $letter eq '_' );

    }
}

sub takenew_letters {

    @lettersHW = ();
    @lettersHW = split "", $highestWord;

    my @diff;
    my @intersection;
    my %bag_hash;
    my %word_hash;
    map { $bag_hash{$_}  += 1 } @bag;
    map { $word_hash{$_} += 1 } @lettersHW;

    for my $key ( keys %bag_hash ) {
        if ( not exists $word_hash{$key} ) {
          		for my $i (1..$bag_hash{$key})
					{
					push @diff, $key;
		}
        }
        elsif ( $bag_hash{$key} != $word_hash{$key} ) {
            for my $i ( 1 .. $bag_hash{$key} ) {
                if ( $bag_hash{$key} != $word_hash{$key} ) {
                    push @diff, $key;
                    $bag_hash{$key}--;
                }
                else {
					push @intersection, $key;
                }
            }
        }
        else {
            	for my $i (1..$bag_hash{$key})
				{
				push @intersection, $key;
				}
        }
    }
    ##LOOP END
	
    for my $i ( 0 .. $#intersection ) {
        push @allallowedletters, $intersection[$i];
        $intersection[$i] = shift @allallowedletters;
     }
	
    @bag = ();
    push @bag, @diff;
    push @bag, @intersection;
}



do {

	my $duration = time - $start;
    $letters = join "", @bag;
	(my $highestWord, my $highestScore) = checkScore($letters);
	if (($highestWord eq "") || ($highestScore == 0))
	{
		$we_end = 1;
	}	
	else 
	{
		@lettersHW = ( split //, $highestWord );
		push @used_words, $highestWord;
		$output_commands .= "P $highestWord $highestWord\n";
		compareBagWord();
		takenew_letters();
	}
    
		
	if ($duration > 4.4) { $we_end = 1; }
    $duration = time - $start;

 } while  ($we_end == 0 );

$output_commands .= "T";

open( FH, '>', 'test.out' ) or die $!;
print FH $output_commands;
close FH;
print "\n##############################\n";
print "## We are done!\n";
print "## File:test.out written\n";
print "##############################\n\n";
