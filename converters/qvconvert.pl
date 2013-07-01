#! /usr/bin/perl

# Description: Quagga to Vyatta configuration converter
# Date: May 2011
# Version: 0.1

# **** MIT License ****
# Copyright (c) 2011 Daniil Baturin <daniil@baturin.org>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# **** End License ****


use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

# Show help
sub usage
{
    print "Usage:".$0." --config=/path/to/quagga/config\n";
    print "Options:\n";
    print "    --rule-step=n    Step between rule numbers in policy objects (e.g. access-lists)\n";
    print "    --first-rule=n   First rule number in policy objects\n";
    exit(0);
}

sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


# Print help if not one command line argument is given
if( @ARGV == 0 ) {
    usage();
}

# Get options
my $file;
my $rule_step = 10; # Default rule step
my $first_rule = 10; # Default first rule number

GetOptions(
  "config=s" => \$file,
  "rule-step=s" => \$rule_step,
  "first-rule=s" => \$first_rule
);

# Read configuration file to array
open(CONFIG, $file) || die("Can not open file: ".$file);
my @quagga_config = <CONFIG>;
close(CONFIG);

# Parameters that should be set if found in any line
my $ip_forwarding = 0;
my $ipv6_forwarding = 0;

# Rule numbers for access-list processing
my $acl = 0;
my $acl_rule = 0;

# Route-map beginning string
my $rm_begin = '';
my $pl = '';

foreach(@quagga_config)
{
     # Search for "ip route <subnet/mask> <iface|gateway>" statement
     if( $_ =~ /^ip route/ ) 
     {
         my @words = split( / /, $_ );
         my $route_command = '';

         if( $words[3] =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ )
         {
             # It's an ordinary route
             $route_command = "set protocols static route ".$words[2]." next-hop ".$words[3];
         }
         elsif( $words[3] =~ /Null0/ )
         {
             # It's a blackhole route
             $route_command = "set protocols static route ".$words[2]." blackhole\n";
         }
         else
         {
             # It's an interface route
             $route_command = "set protocols static interface-route ".$words[2]." next-hop-interface ".$words[3];
         }

         if( $words[4] )
         {
             # Route has distance
             $route_command .= " distance ".$words[4];
         }

         print $route_command;
     }

    # Search for "ipv6 route <subnet/mask> <iface|gateway>" statement
    if( $_ =~ /^ipv6 route/ )
    {
       my @words = split( / /, $_ );
       my $route_command = '';
      
       if( $words[3] =~ /:/ )
       {
           # Interface name can not contain ":", thus it's an IPv6 gateway address
           $route_command = "set protocols static route6 ".$words[2]." next-hop ".$words[3];
       }
       elsif( $words[3] =~ /blackhole/ )
       {
           # It's a blackhole route
           $route_command = "set protocols static route6 ".$words[2]." blackhole\n";
       }
       else
       {
           # Otherwise it's an interface route
           $route_command = "set protocols static interface-route6 ".$words[2]." next-hop-interface ".$words[3];
       }

       if( $words[4] )
       {
           # Route has distance
           $route_command .= " distance ".$words[4];
       }

       print $route_command;
    }

    # Search for "ip forwarding" statement
    if( $_ =~ /^ip forwarding/ )
    {
        $ip_forwarding = 1;
    }

    # Search for "ipv6 forwarding" statement
    if( $_ =~ /^ipv6 forwarding/ )
    {
        $ipv6_forwarding = 1;
    }

    # Search for "ip prefix-list" statement
    if( $_ =~ /^ip prefix-list/ )
    {
        my @words = split( / /, $_ );

        my $pl_begin = "set policy prefix-list ".$words[2]." rule ".$words[4];

        print $pl_begin." action ".$words[5]."\n";
        print $pl_begin." prefix ".$words[6]."\n";
        if( $words[7] )
        {
            # It has "le" or "ge" statement
            print $pl_begin." ".$words[7]." ".$words[8];
        }
    }

    # Search for "ipv6 prefix-list" statement
    if( $_ =~ /^ipv6 prefix-list/ )
    {
        my @words = split( / /, $_ );

        $acl_rule += $rule_step;
        if( $pl ne $words[2] )
        {
            # Previous access list has ended, reset rule counter
            $acl_rule = $first_rule;
            $pl = $words[2];
        }
        
        if( $acl_rule > 65535 )
        {
            print "Error: access-list rule number exceeded allowed value!\n";
            print "Try decreasing rule step by using --rule-step=n option";
            exit(1);
        }
        my $pl_begin = "set policy prefix-list6 ".$words[2]." rule ".$acl_rule;

        print $pl_begin." action ".$words[3]."\n";
        print $pl_begin." prefix ".$words[4]."\n";
        if( $words[6] )
        {
            # It has "le" or "ge" statement
            print $pl_begin." ".$words[5]." ".$words[6];
        }
    }

    # Search for "access-list" statement
    if( $_ =~ /^access-list/ )
    {
        my @words = split( / /, $_ );

        if( $acl ne $words[1] )
        {
            # Previous access list has ended, reset rule counter
            $acl_rule = $first_rule;
        }
        
        if( $acl_rule > 65535 )
        {
            print "Error: access-list rule number exceeded allowed value!\n";
            print "Try decreasing rule step by using --rule-step=n option";
            exit(1);
        }

        $acl = $words[1];
        my $acl_begin = "set policy access-list ".$acl." rule ";

        print $acl_begin.$acl_rule." action ".$words[2]."\n";
                
        if( $words[3] ne "ip" )
        {
            # It's a standard ACL

            if( $words[3] =~ /any/ )
            {
                print $acl_begin.$acl_rule." source ".$words[3]."\n";
            }
            elsif( $words[4] )
            {
                # ACL has network and inverse mask
                print $acl_begin.$acl_rule." source network ".$words[3]."\n";
                print $acl_begin.$acl_rule." source inverse-mask ".$words[4]."\n";
            }
            else
            {
                # ACL has host only
                print $acl_begin.$acl_rule." source host ".$words[3]."\n";
            }
        }
        else
        {
            # It's an extended ACL

            my $next_word = 0;
            
            # Get source
            if( $words[4] =~ /any/ )
            {
                print $acl_begin.$acl_rule." source any\n";
                $next_word = 5;
            }
            elsif( $words[4] =~ /host/ )
            {
                print $acl_begin.$acl_rule." source host ".$words[5]."\n";
                $next_word = 6;
            }
            else
            {
                print $acl_begin.$acl_rule." source network ".$words[4]."\n";
                print $acl_begin.$acl_rule." source inverse-mask ".$words[5]."\n";
                 $next_word = 6;
            }

            # Get destination
            if( $words[$next_word] =~ /any/ )
            {
                print $acl_begin.$acl_rule." destination any\n";
            }
            elsif( $words[$next_word] =~ /host/ )
            {
                print $acl_begin.$acl_rule." destination host ".$words[$next_word+1];
            }
            else
            {
                print $acl_begin.$acl_rule." destination network ".$words[$next_word]."\n";
                print $acl_begin.$acl_rule." destination inverse-mask ".$words[$next_word+1]."\n";
            }
        }

        $acl_rule += $rule_step;
    }
    
    # Search for "ipv6 access-list" statement
    if( $_ =~ /^ipv6 access-list/ )
    {
        my @words = split( / /, $_ );
        
        if( $acl ne $words[2] )
        {
            # Previous ACL has ended, reset rule counter
            $acl_rule = $first_rule;
        }
        
        if( $acl_rule > 65535 )
        {
            print "Error: access-list6 rule number exceeded allowed value!\n";
            print "Try decreasing rule step by using --rule-step=n option";
            exit(1);
        }       
        
        $acl = $words[2];
        my $acl6_begin = "ipv6 access-list ".$acl." rule ";
        
        print $acl6_begin.$acl_rule." action ".$words[3]."\n";
        
        if( $words[4] =~ /any/ )
        {
            print $acl6_begin.$acl_rule." source any\n";
        }
        else
        {
            print $acl6_begin.$acl_rule." source network ".$words[4]."\n";
        }
        
        if( $words[5] )
        {
            print $acl6_begin.$acl_rule." source exact-match\n";
        }
        
        $acl_rule += $rule_step;
    }
    
    # Search for "ip as-path access-list" statement
    if( $_ =~ /^ip as-path access-list/ )
    {
        my @words = split( / /, $_ );
        
        if( $acl ne $words[3] )
        {
            # Previous ACL has ended, reset rule counter
            $acl_rule = $first_rule;
        }
        
        if( $acl_rule > 65535 )
        {
            print "Error: as-path-list rule number exceeded allowed value!\n";
            print "Try decreasing rule step by using --rule-step=n option";
            exit(1);
        }       
        
        $acl = $words[3];
        my $as_path_begin = "set policy as-path-list ".$acl." rule ";
        
        print $as_path_begin.$acl_rule." action ".$words[4]."\n";
        print $as_path_begin.$acl_rule." regex \"".trim($words[5])."\"\n";
        
        $acl_rule += $rule_step;
    }
    
    # Search for "ip community-list" statement
    if( $_ =~ /^ip community-list/ )
    {
        my @words = split( / /, $_ );
        
        if( $acl ne $words[2] )
        {
            # Previous ACL has ended, reset rule counter
            $acl_rule = $first_rule;
        }
        
        if( $acl_rule > 65535 )
        {
            print "Error: community-list rule number exceeded allowed value!\n";
            print "Try decreasing rule step by using --rule-step=n option";
            exit(1);
        }       
        
        $acl = $words[2];
        my $comm_begin = "set policy community-list ".$acl." rule ";
        
        print $comm_begin.$acl_rule." action ".$words[3]."\n";
        print $comm_begin.$acl_rule." regex \"".trim($words[4])."\"\n";
        
        $acl_rule += $rule_step;
    }
    
    # Search for "route-map" statement
    if( $_ =~ /^route-map/ )
    {
        my @words = split( / /, $_ );
        
        $rm_begin = "set policy route-map ".$words[1]." rule ".trim($words[3])." ";
        
        print $rm_begin."action ".$words[2]."\n";
    }
    
    if( trim($_) =~ /^match|on-match|set|call/ )
    {
        # It's a line from route-map
        if( $_ =~ /next-hop/ )
        {
            my @words = split( / /, trim($_) );
            print $rm_begin."set ip-next-hop ".$words[3]."\n";
        }
        else
        {
           print $rm_begin.$_;
        }
    }
}


# If forwarding statements weren't found, forwarding should be disabled
# (enabled by default in Vyatta)
if( !$ip_forwarding )
{
    print "set system ip disable-forwarding";
}

if( !$ipv6_forwarding )
{
    print "set system ipv6 disable-forwarding";
}
