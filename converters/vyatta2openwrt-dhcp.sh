#!/bin/bash
#
# Export Vyatta/EdgeOS DHCP static mappings to OpenWRT format
#
# Copyright (C) 2013 by Daniil Baturin <daniil at baturin dot org>
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

# OpenWRT format:
# config 'host'
#        option 'mac' '00:aa:bb:cc:dd:ee'
#        option 'ip' '192.0.2.150'
#        option 'name' 'some-host'

API=/bin/cli-shell-api
DHCP_PATH="service dhcp-server shared-network-name $1 subnet $2 static-mapping"


function usage
{
    echo "Usage: $0 <share-network-name> <subnet>"
    echo "Example: $0 LAN 192.168.1.0/24"
    exit 1
}

if [ $# != 2 ]; then
    usage
fi

if ! $API exists $DHCP_PATH; then
    echo "Specified subnet does not exist or has no static mappings"
    exit 1
fi

host_list=$($API listNodes $DHCP_PATH)
#echo $host_list
eval "HOSTS=($host_list)"

for i in "${HOSTS[@]}"; do
        echo "config 'host'"
        echo "        option 'mac' '$($API returnValue $DHCP_PATH $i mac-address)'"
        echo "        option 'ip' '$($API returnValue $DHCP_PATH $i ip-address)'"
        echo "        option 'name' '$i'"
done
