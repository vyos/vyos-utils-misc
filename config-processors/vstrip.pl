#!/usr/bin/perl
#
# Removes private information from Vyatta config files.
#
# Copyright (C) 2011 Daniil Baturin <daniil@baturin.org>
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

use strict;
use Getopt::Long;

sub help {
        my $msg = <<EOL;
Strips off private information from Vyatta configs.

Usage: $0 </path/to/config>
       $0 --stdin < </path/to/config> (or "cat /path/to/config | $0 --stdin")

Options:
--stdin        Read config from standard input

--strict       Remove any private information (see details in options below).
               This is default behavior.

--loose        Remove only information specified in options below

--address      Strip off IPv4 and IPv6 addresses
--mac          Strip off MAC addresses
--domain       Strip off domain names
--hostname     Strip off system host and domain names
--username     Strip off user names
--dhcp         Strip off DHCP shared network and static mapping names
--asn          Strip off BGP ASNs
--lldp         Strip off LLDP location information
--snmp         Strip off SNMP location information

EOL
        print $msg;
}

my $inputFile           = undef;
my $stdin               = undef;
my $strict              = 1;
my $loose               = undef;
my $stripIP             = undef;
my $stripDomains        = undef;
my $stripHostname       = undef;
my $stripUsernames      = undef;
my $stripDHCP           = undef;
my $stripMAC            = undef;
my $stripOvpnSecrets    = undef;
my $stripASN            = undef;
my $stripLLDP           = undef;
my $stripSNMP           = undef;
my $keepPasswords       = undef;
my $input               = undef;

GetOptions(
	"stdin"             => \$stdin,
	"loose"             => \$loose,
	"strict"            => \$strict,
	"address"           => \$stripIP,
	"domain"            => \$stripDomains,
	"hostname"          => \$stripHostname,
	"username"          => \$stripUsernames,
	"mac"               => \$stripMAC,
	"dhcp"              => \$stripDHCP,
        "openvpn"           => \$stripOvpnSecrets,
	"asn"               => \$stripASN,
	"lldp"              => \$stripLLDP,
	"snmp"              => \$stripSNMP,
	"keep-passwords"    => \$keepPasswords
);

$strict = 0 if $loose;

if ($strict) {
        $stripIP = 1;
        $stripDomains = 1;
        $stripHostname = 1;
        $stripUsernames = 1;
        $stripDHCP = 1;
        $stripMAC = 1;
        $stripOvpnSecrets = 1;
        $stripASN = 1;
        $stripLLDP = 1;
        $stripSNMP = 1;
}

## Get config

$inputFile = @ARGV[0];

if ($stdin) {
	while (<>) {
		$input .= $_;
	}
} elsif ($inputFile) {
	open (HANDLE, "<$inputFile") or die "Can not open config file $inputFile";
	while (<HANDLE>) {
		$input .= $_;
	}
	close (HANDLE) or die $!;
} else {
	help();
	exit(0);
}

## Everybody stand back, I know regular expressions

# Strip passwords
$input =~ s/password \S+/password xxxxxx/g if !($keepPasswords);

# Strip MAC addresses
$input =~ s/([0-9A-F]{2}\:){3}([0-9A-F]{2}((\:{0,1})){3})/XX:XX:XX:$2/gi if $stripMAC;

# Strip IPv4 addresses
$input =~ s/\d+\.\d+\.(\d+)\.(\d+)/xxx.xxx.$1.$2/g if $stripIP;

# Strip IPv6 addresses
$input =~ s/ (([0-9a-f]{1,4}\:){2})(\S+)/ xxxx:xxxx:$3/gi if $stripIP;

# Strip host-name, domain-name, and domain-search
$input =~ s/(host-name|domain-name|domain-search) \S+/$1 xxxxxx/g if $stripHostname;

# Strip user-names
$input =~ s/(user|username|user-id|login|full-name) \S+/$1 xxxxxx/g if $stripUsernames;

# Strip DHCP static-mapping and shared network names
$input =~ s/(shared-network-name|static-mapping) \S+/$1 xxxxxx/g if $stripDHCP;

# Strip host/domain names
$input =~ s/ (peer|remote-host|local-host|server) ([\w-]+\.)+[\w-]+/ $1 xxxxx.tld/g if $stripDomains;

# Strip OpenVPN secrets
$input =~ s/(shared-secret-key-file|ca-cert-file|cert-file|dh-file|key-file|client) (\S+)/$1 xxxxxx/g if $stripOvpnSecrets;

# Strip BGP ASNs
$input =~ s/(bgp|remote-as) (\d+)/$1 XXXXXX/g if $stripASN;

# Strip LLDP location parameters
$input =~ s/(altitude|datum|latitude|longitude|ca-value|country-code) (\S+)/$1 xxxxxx/g if $stripLLDP;

# Strip SNMP location
$input =~ s/(location) \S+/$1 xxxxxx/g if $stripSNMP;

print $input;

exit(0);
