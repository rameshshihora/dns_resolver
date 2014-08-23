#!/usr/local/bin/perl 
######################################################################################################################
##<purpose> DNS Resolver performance Monitoring
##
## Note: +time=T - Sets the timeout for a query to T seconds. The default timeout is 5 seconds. An attempt to set T to less than 1 will result in a query timeout of 1 second being applied.
## resolution=1 - Look at the below domain and try resolving it. May be one or more domain is NOT resolving. 
## resolverstatus=1 - This means one or more domain resolution didnt go through primary resolver in /etc/resolv.conf. Investigate by quering to Primary.. 
## queryavg - This indicates the average query resolution time and the values are in Milli Seconds
## TtlLkupTime - This is total time taken to resolve all the dns domains query lookup and the values are in Seconds
## Contact: rameshshihora@gmail.com
######################################################################################################################
#use strict;
use warnings;

# Calculating the total time it takes to do the all the domains resolutions
BEGIN { $start_run = time(); }

my @domain = ('facebook.com', 'rocketmail.com', 'techcrunch.com', 'google.com', 'flickr.com', 
	      'yahoo.com', 'yahoo.com', 'google.com', 'apple.com', 'cnn.com' );

my $DEBUG = 0;
my $timeout = 5;

my $outfile = '/tmp/test';
my $out = '/home/y/var/ymailmon_client/DNS';
my ($NS, @avgquery, $ResolvedthroughIP, $avg, $avgtotal, $line);
my ( @dns, $nextline, @resolution, $resolve );

open my $file, '<', '/etc/resolv.conf'   # 3 arg open is safer
     or die "could not open file: $!"; # checking for errors is good

print "DEBUG: Total NameServer Entry from /etc/resolv.conf:: START:\n" if($DEBUG);
while (<$file>)
{
        my $var = $_ ;
        chomp($var);
        if ($var =~ m/(\d+)\.(\d+)\.(\d+)\.(\d+)/)
        {
                $var =~ s/nameserver //g;
                $var =~ s/.*127.0.0.1//g;
		print "DEBUG: $var:\n" if($DEBUG);
                push(@dns, $var);
        }
}
close $file;
print "DEBUG: NameServer Name Printing END:\n\n" if($DEBUG);

print "DEBUG: Primary NameServer Name:\n" if($DEBUG);
$NS = shift(@dns) ;
$NS =~ s/#.*//g;
$NS =~ s/ *$//;
$NS =~ s/^ *//;
print "DEBUG: $NS \n\n" if($DEBUG);


print "DEBUG: Domain Should have three Entry:(Query_time:Resolver:Domain_IP): If NOT then troubleshoot that Domain \n\n" if($DEBUG);

foreach my $dname (@domain) 
{
	open (my $fh, '>', $outfile) or die "Could not open file '$outfile' $!";
        my @test = qx(/usr/bin/dig +stats +nocmd +time="$timeout" "$dname" );
	foreach my $t (@test) 
	{
		chomp($t);
        	print $fh "$t\n";
                
		$t =~ s/\#.*//g;
                $t =~ s/;; //g;
                $t =~ s/msec//g;
                
		if( $t =~ /SERVER: (\d+)\.(\d+)\.(\d+)\.(\d+)/ )
                {
                	$ResolvedthroughIP="$1.$2.$3.$4";
			print "DEBUG: Domain::Resolver   :: $dname\t= $ResolvedthroughIP \n" if($DEBUG);	
                }
                if( $t =~ /Query time: (\d+)/ )
                {
                	push(@avgquery, $1);
			print "DEBUG: Domain::Query_Time :: $dname\t= $1 msec \n" if($DEBUG);
                }
	}
	close $fh;

	open (my $fop, '<', $outfile) or die $!;
	my @goodfile = <$fop>;
	close $fop;
	
	if ( grep { chomp; $_ eq ';; ANSWER SECTION:' } @goodfile )
	{	
		open (TEXT_FILE, "<$outfile");
		while ($line = <TEXT_FILE>) 
		{
  			if ($line =~ m/;; ANSWER SECTION:/) 
			{
             			$nextline = <TEXT_FILE> ;
               			if( $nextline =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ )
               			{
					$resolve=0;
					push(@resolution, $resolve);
					print "DEBUG: Domain::Domain_IP  :: $dname\t= $1.$2.$3.$4\n" if($DEBUG);
               			}
               			else
               			{
					$resolve=1;
                                        push(@resolution, $resolve);
               			}
       			}	 
		}	 
		close (TEXT_FILE);
	}	
	else 
	{ 
		$resolve=1;
                push(@resolution, $resolve);
	}
	print "DEBUG: \n" if($DEBUG);
}

open (my $fp, '>', $out) or die $!;
print $fp "DNS:";
if ( grep { chomp; $_ eq '1' } @resolution ) 
{
	print $fp "resolution=1,"; #Resolution error
}
else
{
	print $fp "resolution=0,"; #Resolution works		
}

if( "$ResolvedthroughIP" ne "$NS" )
{
        if ( "$ResolvedthroughIP" eq "127.0.0.1" )
        {       
                print $fp "rsolrstats=0,"; # 1 = OK
        }       
        else            
        {       
                print $fp "rsolrstats=1,"; # 1 = CRITICAL
        }               
}               
else    
{
        print $fp "rsolrstats=0,"; # 0 = OK
}
        
$avg = &average(\@avgquery);
$avgtotal = sprintf("%.0f", $avg);
                
print $fp "queryavg=$avgtotal,";

sub average{
        my($data) = @_;
        if (not @$data) {
                die("Empty array\n");
        }
        my $total = 0;
        foreach (@$data) {
                $total += $_;
        }
        my $average = $total / @$data;
        return $average;
}

my $end_run = time();
my $run_time = $end_run - $start_run;

print $fp "TtlLkupTime=$run_time\n";
close $fp;

print "DEBUG: The Final output wrote to a file : $out \n" if ($DEBUG);
my $debugout=qx(cat "$out");
print "DEBUG: $debugout \n" if($DEBUG);
