#!/usr/bin/perl

# Copyright (C) 2011 by Daniil M. Baturin <daniil at baturin dot org>

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

use strict;
use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Getopt::Long;

my $help = <<EOL;
Export remote access VPN users into text or CSV from Vyatta 6.3 or higher.

Options:
--proto=<pptp|l2tp>            Protocol to export users
--csv                          Export to CSV (Comma Separated Values, RFC4180)
--delimiter=<some character>   Use given character as value delimiter 
                               instead of comma in CSV (e.g. ";")
EOL

if ($#ARGV < 0) { # No arguments given
    print $help;
    exit(0);
}

my $proto = undef;
my $delimiter = undef;
my $csv = undef;

GetOptions(
    "proto=s" => \$proto,
    "delimiter=s" => \$delimiter,
    "csv" =>  \$csv
);

die("No protocol specified! Please specify --proto=pptp or --proto=l2tp")
    unless $proto;

# Lowercase protocol name
$proto = lc($proto);
print "$proto\n";

if ( $proto !~ m/(^pptp|l2tp$)/ ) {
    die("Unknown protocol $proto! Must be pptp or l2tp.\n");
}

$delimiter = "," unless $delimiter;

my $config = new Vyatta::Config;
my $hostname = $config->returnValue("system host-name");
my $domainName = $config->returnValue("system domain-name");
my $domainString = $domainName if $domainName;
my $displayProto = uc($proto);

my $humanHeader = <<EOL;
$displayProto users at $hostname\@$domainString:

User            Password            Address         Disabled
--------------- ------------------- --------------- ---------

EOL

my $csvHeader = "user,password,address,disabled\r\n";
my $header = $csv ? $csvHeader : $humanHeader;
print $header;

$config->setLevel("vpn $proto remote-access authentication local-users username");
my @users = $config->listNodes();

foreach my $user (@users) {
    my $password = $config->returnValue("$user password");
    my $address = $config->returnValue("$user static-ip");
    my $disabled = $config->exists("$user disable") ? "yes" : "no";

    if ($csv) {
        # Double quotes inside config aren't allowed right now,
        # but this may change in the future
        $password =~ s/(\")/\"\"/g;
        $password = "\"$password\"";

        my $line = join($delimiter, $user, $password, $address, $disabled);
        print "$line\r\n";
    }
    else {
        printf "%-15s %-20s %-15s %-8s\n", 
               $user, $password, $address, $disabled;
    }
}
