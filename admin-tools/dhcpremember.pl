#!/usr/bin/env perl
#
# Generates static mapping commands from the DHCP leases op mode command output
#
# On VyOS and Vyatta, invoke like "run show dhcp server leases | /config/scripts/dhcpremember.pl"
# On EdgeOS, invoke like "run show dhcp leases | /config/scripts/dhcpremember.pl"
#
# Copyright (C) 2014 Daniil Baturin
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

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

