#!/usr/bin/perl
#
# Show configurable bars for df output. GPLv2+
#
use strict;
use warnings;
use Getopt::Std;

my %config = ( ver        =>  'V1.1',
               df         =>  '/bin/df -k',
               maxbarlen  => 20,
               width      => 1,
               fcol       => "\33[44m",
               gcol       => "\33[41m",
               ecol       => "\33[0m",
               rcol       => "\33[0m",
               altcol     => "",
               used       => ' ',
               unused     => '-',
               delim      => ':');

# If dfg appears to produce totally screwed up output. Try changing
# the parameter for df. Some examples worth trying are:
#
# df -P
# df -h
# df -H
# df -b
# df -m
# df (no parameters)

###Process command line arguments
my %args;
getopts('l:w:c:s:h:d:', \%args); #Char for unused part of bar

if (defined $args{h}) { &error(); }
if (defined $args{d}) { &docs(); }

if (defined $args{l})
{
	if ($args{l} < 5) { &error("Error: Bar length must at least 5"); }
	else { $config{maxbarlen} = $args{l}; }
}

if (defined $args{w})
{
	if ($args{w} < 1 ) { &error("Error: Bar width must be at least 1"); }
	else { $config{width} = $args{w}; }
}

if (defined $args{c})
{
	if (length($args{c}) != 3) { &error("Error: Invalid colour specification"); }
	else
	{
		if (substr($args{c}, 0, 1) == 0)
			{$config{fcol} = "\33[40m";}
		else
			{$config{fcol} = "\33[4".substr($args{c}, 0, 1) . "m";}

		if (substr($args{c}, 1, 1) == 0)
			{$config{gcol} = "\33[40m";}
		else
			{$config{gcol} = "\33[4".substr($args{c}, 1, 1) . "m";}

		if (substr($args{c}, 2, 1) == 0)
			{$config{ecol} = "\33[40m";}
		else
			{$config{ecol} = "\33[4".substr($args{c}, 2, 1) . "m";}
	}
}

if (defined $args{s})
{
	if (length($args{s}) !=3)
		{&error("Error: Invalid character specification");}
	else
	{
		$config{used} = substr($args{s}, 0, 1);
		$config{unused} = substr($args{s}, 1, 1);
		$config{delim} = substr($args{s}, 2, 1);
	}
}

open (DF, "$config{df} |");
my @df=<DF>;
close (DF);

shift @df;	# Shift to remove the field titles

foreach my $entry (@df)
{
    # Get rid of any % symbols
    $entry =~ s/%//g;

    # For drawing alternating colours
    if ($config{altcol} eq $config{fcol}) { $config{altcol} = $config{gcol}; }
    else { $config{altcol} = $config{fcol}; }

	my ($device, $size, $used, $avail, $pcused, $mntpnt) = split /\ +/, $entry;
	my $barlen = int(($pcused * $config{maxbarlen}) / 100);
	my $bglen = int($config{maxbarlen} - $barlen);

	if (length($pcused) > $barlen)
		{$pcused = "";}
	else
		{$barlen = $barlen - length($pcused);}

	if (int($config{width}/2) == ($config{width}/2)) # Test for odd/even widths
	{
		for ($b=1; $b<int($config{width}/2); $b++)
			{&bar("0", $config{altcol}, $pcused, $barlen, $mntpnt, $device, $bglen);}
	}
	else
	{
		for ($b=0; $b<int($config{width}/2); $b++)
			{&bar("0", $config{altcol}, $pcused, $barlen, $mntpnt, $device, $bglen);}
	}

	&bar("1", $config{altcol}, $pcused, $barlen, $mntpnt, $device, $bglen);
	for ($b=0; $b<int($config{width}/2); $b++)
		{&bar("0", $config{altcol}, $pcused, $barlen, $mntpnt, $device, $bglen);}
}

print "\n";
exit 0;

sub bar()
{
    my ($type, $col, $pcused, $barlen, $mntpnt, $device, $bglen) = @_;

	if ($type eq "0") { printf "$config{rcol}$config{delim}\33[4" . $col . $config{used} x ($barlen + length($pcused)) . "$config{ecol}" . $config{unused} x $bglen . "$config{rcol}$config{delim}\n"; }
	else              { printf "$config{rcol}$config{delim}\33[4" . $col . $config{used} x $barlen . "$pcused$config{ecol}" . $config{unused} x $bglen . "$config{rcol}$config{delim} %-9s $mntpnt", $device;}
}

sub error()
{
if (defined $_[0]) { print "$_[0]\n\n"; }

print STDERR <<QUICKDOCS;
dfg $config{ver} by Ian Chapman
Options:
       [-l] : Bar Lengths (Minimum 4)
       [-w] : Bar width
       [-c] : Colour specification in XXX format
              eg 432 (means blue, yellow, green)
       [-s] : Chars to use for bar and delimeter
              eg \"\#\.\!\"
    [-help] : Show Parameters
    [-docs] : Display documentation

QUICKDOCS
exit 1;
}

sub docs
{
print <<DOCS;
dfg $config{ver} By Ian Chapman
-----------------------

dfg displays a horizontal configurable colour graph of your disk usage
on the console.

LICENSE AND DISCLAIMER
----------------------

dfg is licensed under the GPL V2+

PARAMETERS
----------

All parameters are optional.

    -c : Default: 410
         Specifies the colours to use for the graph. The value should be
         between 000 and 777. The first two digits represent the colours
         to use for the bars, which are alternated. The third digit
         represents the colour of the bar's background.
         (Note: See colour table below)

    -s : Default: " -:"
         A three character string which describes what characters to use
         for the graph. The first character is used to draw the bar, the
         second is used to draw the bar's background and the third is the
         delimeter character. Note: Some characters may need escaping,
         such as * which should be written as \\* or depending on your
         shell you can enclose them in speech marks. For example:

         "*-!" : This means use * for the bars, use - for the bar's
         background and use ! for the delimeter. You can also use the
         space character which is not as stupid as it may sound. Try it
         :-)

    -l : Default: 20
         Specifies the length of the bars (in characters)

    -w : Default: 1
	 Specifies the width of the bars (in characters)

 -help : Displays a quick summary of the parameters

 -docs : Displays this documentation

COLOUR TABLE
------------

  0 : BLACK
  1 : RED
  2 : GREEN
  3 : YELLOW (OR ORANGE)
  4 : BLUE
  5 : MAGENTA (PINK)
  6 : CYAN (TURQOISE)
  7 : WHITE

TIPS
----

1. If you wish to change the default display of dfg, this can be done in two
   ways.

    * Edit the script and set your own defaults. They are contained in
       the parameter parsing section near the top.

    * Add an alias to your profile. The actual format may vary depending
       on  your shell but for example with bash you can do:

	alias dfg=/usr/bin/dfg.pl -c 543 -s "#_|"

        Then simply typing dfg will use these parameters by default.

2. If dfg appears to produce screwed up output, the version of df installed
   on your system may not be compatible. One solution may be to edit the
   script and change the value of \$DFLOC to one of the following:

    df -P
    df -h
    df -H
    df -b
    df -m
    df (no parameters)
DOCS
exit 0;
}

