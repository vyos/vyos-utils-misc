#!/usr/bin/env perl
#
# Generates (incomplete) OpenVPN config for site to site remote endpoint
#
# Copyright (C) 2014 by Daniil Baturin <daniil at baturin dot org>
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

use strict;
use warnings;
use lib "/opt/vyatta/share/perl5";
use Vyatta::Config;

my $intf = $ARGV[0];

die "Please specify OpenVPN interface!" unless defined($intf);

my $config = new Vyatta::Config;
die "Interface $intf does not exist" unless $config->exists("interfaces openvpn $intf");

$config->setLevel("interfaces openvpn $intf");

my @local_address = $config->listNodes("local-address");
my $remote_address = $config->returnValue("remote-address");
my $proto = $config->returnValue("protocol");
my $local_port = $config->returnValue("local-port");
my $remote_port = $config->returnValue("remote-port");
my $local_host = $config->returnValue("local-host");

my $device_type = "tun";
$device_type = "tap" if $config->exists("device-type");

my $ovpn_config = "";


my $defaults = <<EOL;
verb 4
daemon
verb 3
status /var/log/openvpn/s2s_status.log
ping 10
ping-restart 60

EOL

$ovpn_config .= "ifconfig $local_address[0] $remote_address \n";

$ovpn_config .= "proto $proto \n"; # XXX: add TCP

$ovpn_config .= "lport $local_port \n";
$ovpn_config .= "rport $remote_port \n";

$ovpn_config .= "remote $local_host \n";

$ovpn_config .= "dev $device_type \n";

$ovpn_config .= $defaults;

print $ovpn_config;

