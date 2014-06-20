#!/usr/bin/env perl
#
# Joins OpenVPN config, CA, cert, and key into one file.
#
# Copyright (C) 2014 Daniil Baturin <daniil@baturin.org>
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
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


use strict;
use warnings;

## Bundled config template
my $template = <<EOF;

__CONFIG__

<ca>
__CA__
</ca>

<cert>
__CERT__
</cert>

<key>
__KEY__
</key>

EOF
## End template

sub read_file
{
    my $file = shift;
    open(FILE, $file) or die "Can't read file $file [$!]\n";  
    my $contents = do { local $/; <FILE> };
    close (FILE); 
    return($contents);
}

## main()
if( $#ARGV != 3 )
{
    die("Usage: $0 <config file> <CA cert file> <cert file> <key file>");
}

my $config_file = $ARGV[0];
my $ca_file = $ARGV[1];
my $cert_file = $ARGV[2];
my $key_file = $ARGV[3];

## Read files
my $config = read_file($config_file);
my $ca = read_file($ca_file);
my $cert = read_file($cert_file);
my $key = read_file($key_file);

## Process the template
$template =~ s/__CONFIG__/$config/;
$template =~ s/__CA__/$ca/;
$template =~ s/__CERT__/$cert/;
$template =~ s/__KEY__/$key/;

print $template;
