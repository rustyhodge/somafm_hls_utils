#!/usr/bin/perl

## Version 0.70 9-May-2024
## Typical use is piping through sort -n to see to top connection times.

## Bugs
## Does not take into account a user disconnecting and reconnecting (Serious bug)

use strict;
use warnings;
use File::Tail;
use Time::Piece;


my $filename = '/var/log/nginx/access.log';
my $num_lines_to_read = 1000;
my $tailFmode = 0;
my $maxlines=0 	  ;


my $current_time = localtime;

# Subtract one minute from the current time
my $previous_minute = $current_time - 60;

# Get the log format matching
my $previous_period_time = $previous_minute->strftime("%d/%b/%Y:%H:%M");

my $counter;

my %firstSeen;
my %lastSeen;



open TAIL, "<$filename" || die "Cannot open file '$filename' for reading: $!";

while(<TAIL>) {

	chomp;
	my $line=$_;
	$counter++;
	#print "$counter\n";
	if ($line = Process($line)) {
		####temp print "$line\n";	
	}
}


print "=================== Totals ====================\n";

foreach my $client (sort keys %lastSeen) {


	my $date1 = Time::Piece->strptime($firstSeen{$client}, "%d/%b/%Y:%H:%M:%S %z");
	my $date2 = Time::Piece->strptime($lastSeen{$client}, "%d/%b/%Y:%H:%M:%S %z");

	# Calculate the difference in seconds
	my $minutes = int(($date2 - $date1)/60);


	#printf ("%-7.7s\t%-25.25s %s %s\n", $minutes, $client, $firstSeen{$client}, $lastSeen{$client}, );
	
	printf ("%-7.7s\t%-55.55s   %s\n", $minutes, $client, $firstSeen{$client}, $lastSeen{$client}, );

}

sub Process {
	my($line)=@_;

	if ($line =~ /^(\S+) (\S+) (\S+) \[([^\]]+)\] "([^"]+)" (\d+) (\d+) "([^"]+)" "([^"]+)" "([^"]+)"$/) {
		my ($ip, $dash1, $dash2, $timestamp, $request, $status, $size, $referer, $user_agent, $dash3) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
	
	
		return ('') unless ($request=~/GET /);
		#
		$request=~s/^GET //g;
		$request=~s/\/\//\//g;
		$request=~s/ HTTP\/.*//;
		my ($uuid)='';
		#This is broken!
		if ($request =~ /id=([A-Za-z0-9\-]+)/) {
			$uuid=$1;
			#print "Got $uuid\n";
		}
		
		$request=~s/\?.*//g;
		
		if ($uuid) {
			$ip.='-' . $uuid;
		}
		
		#return ('') if ($request=~/program_init.mp4/);
		return ('') unless ($request=~/\/program.m3u8/);
		#return ('') unless ($request=~/^\/hls\//);

	#	print "$ip-$request\n";
		
		
		my $ipRequest=sprintf("%-15.15s %s",$ip,$request);
		
		
		$firstSeen{$ipRequest}=$timestamp unless $firstSeen{$ipRequest};
		$lastSeen{$ipRequest}=$timestamp ;
		
		return("$ip $timestamp $request");

	} else {
		return('');
		#print "Line does not match expected format.\n";
	}

}
