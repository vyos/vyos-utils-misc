#!/usr/bin/perl

# Copyright (C) 2011 by Daniil M. Baturin <daniil at baturin dot org>

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
