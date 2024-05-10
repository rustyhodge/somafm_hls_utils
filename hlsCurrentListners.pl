#!/usr/bin/perl

## Author: rusty@somafm.com  2024-05-09
##
## This program will look at the log and output a time stamp
## and the number of listeners. The first listener column 
## includes session info where available, the second is the number
## of uniqie IPs.
##
## Designed to be called from Cron once a minute.
## ToDo: demonize, output to configurable logfiles

## This is for all program URLs.

## ToDo: Version that writes out the listener numbers for all 
## the possible programs.

use strict;
use warnings;
use File::Tail;
use Time::Piece;

#Extra verbosity.  TODO: add to command line.
my $debug=0;


my $filename = '/var/log/nginx/access.log';
#How many lines should we tail. Increase based on the traffic your server gets.
my $maxlines=10000;
#TODO: if the first line read is equal to the timestamp, increase this number and try again.

my $current_time = localtime;

# Subtract one minute from the current time
my $previous_minute = $current_time - 60;

# Get the timestamp for the previous minute
my $previous_period_time = $previous_minute->strftime("%d/%b/%Y:%H:%M");

my $display_previous_period_time = $previous_minute->strftime("%a %b %e %H:%M:%S %Y");

my $listenerIPCount=0;
my $listenerCount=0;
my(%uniqueIPs);
my(%uniqueIPandUID);
	
	
open TAIL, "tail -n $maxlines $filename|" || die "Cannot open file '$filename' for reading: $!";

while(<TAIL>) {

	chomp;
	my $line=$_;
	#my($theip,$request) = Process($line)
	my ($theip, $request) = Process($line);

	if ($theip) {
	 
		print "$theip  -> $request\n" if $debug;	
		
		
		my($iponly)=$theip;
		$iponly=~s/-.*//;
		
		
		unless (exists $uniqueIPs{$iponly}) {
			
			$uniqueIPs{$iponly}++ ;
			$listenerIPCount++ ;
			print "uniqueIPs $iponly $theip\n"; 
		}
		
		unless (exists $uniqueIPandUID{"$theip"}) {
			
			$uniqueIPandUID{"$theip"}++;
			$listenerCount++;
			print "uniqueIPandUID $theip " . $uniqueIPandUID{"$theip"} . "\n"; 
		}
		
	}
}

#Experimenting with different formats
#printf("%5s %s\n",  $listenerCount, $previous_period_time);

print "$previous_period_time\t$listenerCount\t$listenerIPCount\n";



sub Process {
	my($line)=@_;
	my($uuid);
	
	print "\n==== LINE: $line ======\n" if $debug;
	
	if ($line =~ /^(\S+) (\S+) (\S+) \[([^\]]+)\] "([^"]+)" (\d+) (\d+) "([^"]+)" "([^"]+)" "([^"]+)"$/) {
		my ($ip, $dash1, $dash2, $timestamp, $request, $status, $size, $referer, $user_agent, $dash3) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
	

		#Skip unless previous minute		
		return('') unless ($timestamp=~/$previous_period_time/);
		return ('') unless ($request=~/GET /);
		#
		$request=~s/^GET //g;
		$request=~s/\/\//\//g;
		$request=~s/ HTTP\/.*//;
		my ($uuid)='';
		#This is possibly broken for items that have multiple query strings!
		if ($request =~ /id=([A-Za-z0-9\-]+)/) {
			$uuid=$1;
			$uuid=~s/\?.*//; #Hope that fixes it?
			$uuid=~s/\&.*//;
			print "Got $uuid\n" if $debug;
		}
		
		$request=~s/\?.*//g;
		
		if ($uuid) {
			$ip.='-' . $uuid;
		}
		
		print "RETURNING $ip $timestamp $request\n" if $debug;
		
		return ('') unless ($request=~/\/program.m3u8/);
		return($ip,$request);

	} else {
		return('');
		print "Line does not match expected format.\n" if $debug;
	}

}




