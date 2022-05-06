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
TOTALMEM=$(cat /proc/meminfo | grep MemTotal | grep -o '[0-9]*')
TOTALMEMMBROUNDED=$((($TOTALMEM+(1000/2))/1000))
TOTALSWAP=$(cat /proc/meminfo | grep SwapTotal | grep -o '[0-9]*')
TOTALMEMSWAP=$(($TOTALMEM + $TOTALSWAP))
TOTALMEMSWAPGBROUNDED=$((($TOTALMEMSWAP+(1000000/2))/1000000))
TOTALMEMSWAPREQUIRED=4
TOTALSWAPTOADD=$(($TOTALMEMSWAPREQUIRED - $TOTALMEMSWAPGBROUNDED))
G=G

if [[ $TOTALSWAPTOADD -gt 0 ]]
    then
        sudo fallocate -l $TOTALSWAPTOADD$G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        sudo cp /etc/fstab /etc/fstab.bak
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    else
        echo 'Additional swap memory not added as at least 4GB of memory + swap (rounded) has been installed on this server'
fi

sudo apt-get update && sudo apt-get install gnupg1 apt-transport-https dirmngr -y

#Downloading Cloudflare DDNS Script
sudo wget https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns-una.sh -O /usr/local/bin/cloudflare_ddns-una.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns-una.sh -o /usr/local/bin/cloudflare_ddns-una.sh
sudo wget https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_cname-una.sh -O /tmp/cloudflare_cname-una.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_cname-una.sh -o /tmp/cloudflare_cname-una.sh
sudo wget https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns-restoredefault.sh -O /tmp/cloudflare_ddns-restoredefault.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns-restoredefault.sh -o /tmp/cloudflare_ddns-restoredefault.sh

#Downloading Let's Encrypt Script
sudo wget https://raw.githubusercontent.com/jacktooandroid/ubiquitiunificontroller/personal/unifi_LE_ssl.sh -O /usr/local/sbin/unifi_LE_ssl.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/ubiquitiunificontroller/personal/unifi_LE_ssl.sh -o /usr/local/sbin/unifi_LE_ssl.sh

#Adding Sources
echo 'deb https://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/ubnt-unifi.list
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg

#Installing Miscellaneous Software
curl -s https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
sudo apt-get update
sudo apt-get install speedtest haveged certbot fail2ban traceroute glances python3-pip iperf3 lynx miniupnpc dnsutils rng-tools -y
#sudo pip3 install --upgrade setuptools
#sudo pip3 install --upgrade pip
sudo pip3 install --upgrade glances

#Installing Ubiquiti UniFi Controller and Default JRE
sudo apt-mark hold openjdk-11-*
sudo apt-mark hold openjdk-13-*
sudo apt-mark hold openjdk-14-*
sudo apt-mark hold openjdk-16-*
sudo apt-get install unifi -y
#sudo apt-get install default-jre-headless -y
#sudo service unifi restart
#sleep 10

#Configure Ubiquiti UniFi Controller Java Memory (heap size) Allocation
cd /usr/lib/unifi/data
cat system.properties
echo '# Modifications' | sudo tee -a /usr/lib/unifi/data/system.properties
echo 'unifi.xms=256' | sudo tee -a /usr/lib/unifi/data/system.properties

TOTALUNIFIXMX=$((TOTALMEMMBROUNDED-1024))
if [[ $TOTALUNIFIXMX -gt 1024 ]]
    then
        echo 'unifi.xmx='$TOTALUNIFIXMX | sudo tee -a /usr/lib/unifi/data/system.properties
    else
        echo 'unifi.xmx=1024' | sudo tee -a /usr/lib/unifi/data/system.properties
fi

#Custom SSL Configuration
echo 'unifi.https.sslEnabledProtocols=TLSv1.3,TLSv1.2' | sudo tee -a /usr/lib/unifi/data/system.properties
echo 'unifi.https.ciphers=TLS_AES_256_GCM_SHA384,TLS_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256' | sudo tee -a /usr/lib/unifi/data/system.properties

#Enabling High Performance Java Garbage Collector
echo 'unifi.G1GC.enabled=true' | sudo tee -a /usr/lib/unifi/data/system.properties

#Redirect port 443 to 8443
sudo iptables -t nat -I PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443
sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080

#Installing iptables-persistent
echo 'iptables-persistent iptables-persistent/autosave_v4 boolean true' | sudo debconf-set-selections
echo 'iptables-persistent iptables-persistent/autosave_v6 boolean true' | sudo debconf-set-selections
sudo apt-get install iptables-persistent -y

sudo service unifi restart

#MiniUPNP Settings
echo 'upnpc -r 3478 udp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 6789 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 8080 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 8443 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 8880 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 8843 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
#bash /usr/local/bin/miniupnp.sh

exit