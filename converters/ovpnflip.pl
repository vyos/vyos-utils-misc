#!/usr/bin/env perl
#
# Generates (incomplete) OpenVPN config for site to site remote endpoint
#
# Copyright (C) 2014 by Daniil Baturin <daniil at baturin dot org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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

