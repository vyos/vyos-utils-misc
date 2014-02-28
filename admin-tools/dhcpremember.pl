#!/usr/bin/env perl
#
# Generated static mapping from the DHCP leases op mode command output
#
# On VyOS and Vyatta, invoke like "run show dhcp server leases | /config/scripts/dhcpremember.pl"
# On EdgeOS, invoke like "run show dhcp leases | /config/scripts/dhcpremember.pl"
#
# Copyright (C) 2014 Daniil Baturin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use lib "/opt/vyatta/share/perl5/";

use strict;
use warnings;
use Vyatta::Config;
use NetAddr::IP;

my $config = new Vyatta::Config();

while(<>)
{
    # skip headers
    if( $_ !~ /\d\.?/ )
    {
        next;
    }

    # Lease line format: <IPv4> <MAC> <Lease time> <Pool> <Client name>    
    my @values = split /\s+/, $_;
    my $ip = $values[0];
    my $mac = $values[1];
    my $pool = $values[4];
    my $client = undef;
    
    # Client name may not be present
    if( defined($values[5]) )
    {
        $client = $values[5];
    }
    else
    {
        $client = $ip;
    }
    my $subnet = "CHANGME"; # For the case it isn't detected from the config
   
    # Get subnet for the pool
    my @subnets = $config->listNodes("service dhcp-server shared-network-name $pool subnet");
    my $ip_object = new NetAddr::IP("$ip/32");
    foreach my $subnet_str (@subnets)
    {
        my $subnet_object = new NetAddr::IP($subnet_str);
        if( $ip_object->within($subnet_object) )
        {
            $subnet = $subnet_str;
        }
    }
    
    $client = $ip unless defined($client);
    
    print "set service dhcp-server shared-network-name $pool subnet $subnet static-mapping $client ip-address $ip\n";
    print "set service dhcp-server shared-network-name $pool subnet $subnet static-mapping $client mac-address $mac\n";
}

