#!/bin/bash

#License
clear
echo 'MIT License'
echo ''
echo 'Copyright (c) 2018 jacktooandroid'
echo ''
echo 'Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:'
echo ''
echo 'The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.'
echo ''
echo 'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.'
echo ''
echo 'Installation will continue in 3 seconds...'
sleep 3

#Checking Memory Requirements
clear
memtotal=$(cat /proc/meminfo | grep MemTotal | grep -o '[0-9]*')
swaptotal=$(cat /proc/meminfo | grep SwapTotal | grep -o '[0-9]*')
totalmem=$(($memtotal + $swaptotal))

if [[ $totalmem -lt 900000 ]]
    then
        sudo fallocate -l 1G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        sudo cp /etc/fstab /etc/fstab.bak
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

#Installing Ubiquiti UniFi Controller and Default JRE
echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/ubnt-unifi.list
wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg
sudo apt-get update && sudo apt-get install unifi haveged -y
sudo apt-get install default-jre-headless -y
sudo service unifi restart
sleep 5

#Configure Ubiquiti UniFi Controller Java Memory (heap size) Allocation
if [[ $memtotal -gt 900000 ]]
    then
        memtotalinmb=$((memtotal / 1000))
        cd /usr/lib/unifi/data
        cat system.properties
        echo '# Modifications' | sudo tee -a /usr/lib/unifi/data/system.properties
        echo unifi.xms=256 | sudo tee -a /usr/lib/unifi/data/system.properties
        echo unifi.xmx=$memtotalinmb | sudo tee -a /usr/lib/unifi/data/system.properties
    else
        cd /usr/lib/unifi/data
        cat system.properties
        echo '# Modifications' | sudo tee -a /usr/lib/unifi/data/system.properties
        echo unifi.xms=256 | sudo tee -a /usr/lib/unifi/data/system.properties
        echo unifi.xmx=1024 | sudo tee -a /usr/lib/unifi/data/system.properties
fi

sudo service unifi restart
exit