#!/bin/bash

# License
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

clear

# System memory logic(s) and variable(s)
TOTALMEMSWAPREQUIREDGB=2
TOTALMEM=$(cat /proc/meminfo | grep MemTotal | grep -o '[0-9]*')
TOTALMEMGBROUNDED=$((($TOTALMEM+(1000000/2))/1000000))
TOTALSWAP=$(cat /proc/meminfo | grep SwapTotal | grep -o '[0-9]*')
TOTALMEMSWAP=$(($TOTALMEM+$TOTALSWAP))
TOTALMEMSWAPGBROUNDED=$((($TOTALMEMSWAP+(1000000/2))/1000000))
G=G
if [[ $(($TOTALMEMSWAPREQUIREDGB-$TOTALMEMSWAPGBROUNDED)) -gt 0 ]]
    then
        TOTALSWAPTOADDGB=$(($TOTALMEMSWAPREQUIREDGB-$TOTALMEMSWAPGBROUNDED))
    else
        TOTALSWAPTOADDGB=0
fi

# UniFi memory logic(s) and variable(s)
MINIMUMUNIFIXMX=512
if [[ $TOTALMEMGBROUNDED -gt 2 ]]
    then
        TOTALUNIFIXMX=$((($TOTALMEMGBROUNDED-1)*1024/2))
    else
        TOTALUNIFIXMX=$((($TOTALMEMGBROUNDED)*1024/2))
fi

# MongoDB Cache logic(s) and variable(s)
MINIMUMMONGODBCACHE=256
TOTALMONGODBCACHE=$((($TOTALMEMGBROUNDED-1)*1024/2))

# Check memory requirement
if [[ $TOTALSWAPTOADDGB -gt 0 ]]
    then
        sudo fallocate -l $TOTALSWAPTOADDGB$G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        sudo cp /etc/fstab /etc/fstab.bak
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    else
        echo 'Additional swap memory not added as at least '$TOTALMEMSWAPREQUIREDGB'GB of memory + swap (rounded) has been installed on this server'
fi

# Install prerequisites
sudo apt update && sudo apt -y install ca-certificates apt-transport-https gnupg dirmngr curl wget

# Download Cloudflare scripts
sudo wget https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns-una.sh -O /usr/local/bin/cloudflare_ddns-una.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns-una.sh -o /usr/local/bin/cloudflare_ddns-una.sh
sudo wget https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_cname-una.sh -O /tmp/cloudflare_cname-una.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_cname-una.sh -o /tmp/cloudflare_cname-una.sh
sudo wget https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns-restoredefault.sh -O /tmp/cloudflare_ddns-restoredefault.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns-restoredefault.sh -o /tmp/cloudflare_ddns-restoredefault.sh

# Download Let's Encrypt script
sudo wget https://raw.githubusercontent.com/jacktooandroid/ubiquitiunificontroller/personal/unifi_LE_ssl.sh -O /usr/local/sbin/unifi_LE_ssl.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/ubiquitiunificontroller/personal/unifi_LE_ssl.sh -o /usr/local/sbin/unifi_LE_ssl.sh

# Add sources
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo apt-key add -
echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg
echo 'deb [arch=amd64,arm64] https://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/ubnt-unifi.list

# Install miscellaneous software
sudo apt update
# sudo apt install -y haveged 
sudo apt install -y certbot fail2ban glances traceroute lynx dnsutils cron
sudo apt install -y lm-sensors miniupnpc natpmpc
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt install -y speedtest
# sudo pip3 install --upgrade setuptools
# sudo pip3 install --upgrade pip
# sudo pip3 install --upgrade glances

# Install UniFi Network Application and necessary software
# sudo apt install -y openjdk-21-jre-headless
sudo apt install -y temurin-21-jre
# sudo apt install -y mongodb-org-server=8.0.0
sudo apt install -y unifi

# SSL configuration
echo ''
echo "***** /usr/lib/unifi/data/system.properties Configurations *****" | sudo tee -a /tmp/unifi_system.properties_configurations.txt
echo 'unifi.https.sslEnabledProtocols=TLSv1.3,TLSv1.2' | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
echo 'unifi.https.ciphers=TLS_CHACHA20_POLY1305_SHA256,TLS_AES_256_GCM_SHA384,TLS_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256' | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt

# Java heap size configuration
echo 'unifi.xms=256' | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
if [[ $TOTALUNIFIXMX -gt $MINIMUMUNIFIXMX ]]
    then
        echo 'unifi.xmx='$TOTALUNIFIXMX | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
    else
        echo 'unifi.xmx='$MINIMUMUNIFIXMX | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
fi

# MongoDB default cache size configuration
# echo 'db.mongo.wt.cache_size_default=true' | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
if [[ $TOTALMONGODBCACHE -gt $MINIMUMMONGODBCACHE ]]
    then
        echo 'db.mongo.wt.cache_size='$TOTALMONGODBCACHE | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
    else
        echo 'db.mongo.wt.cache_size='$MINIMUMMONGODBCACHE | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
fi

# Inform configuration
echo 'inform.num_thread=200' | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
echo 'inform.max_keep_alive_requests=100' | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt

# Enable high performance Java garbage collector
echo 'unifi.G1GC.enabled=true' | sudo tee -a /usr/lib/unifi/data/system.properties /tmp/unifi_system.properties_configurations.txt
echo ''

# Restart UniFi Network Application to apply configurations
sudo service unifi restart

# Redirect UniFi Network Application ports
sudo iptables -t nat -I PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443
sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080

# Install iptables-persistent
echo 'iptables-persistent iptables-persistent/autosave_v4 boolean true' | sudo debconf-set-selections
echo 'iptables-persistent iptables-persistent/autosave_v6 boolean true' | sudo debconf-set-selections
sudo apt -y install iptables-persistent

# MiniUPNP settings
echo 'upnpc -r 80 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 443 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 6789 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 8080 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 8443 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 8880 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 8843 tcp' | sudo tee -a /usr/local/bin/miniupnp.sh
echo 'upnpc -r 3478 udp' | sudo tee -a /usr/local/bin/miniupnp.sh
# bash /usr/local/bin/miniupnp.sh

# NATPMP settings
echo "natpmpc -a 80 80 tcp" | sudo tee -a /usr/local/bin/natpmp.sh
echo "natpmpc -a 443 443 tcp" | sudo tee -a /usr/local/bin/natpmp.sh
echo "natpmpc -a 6789 6789 tcp" | sudo tee -a /usr/local/bin/natpmp.sh
echo "natpmpc -a 8080 8080 tcp" | sudo tee -a /usr/local/bin/natpmp.sh
echo "natpmpc -a 8443 8443 tcp" | sudo tee -a /usr/local/bin/natpmp.sh
echo "natpmpc -a 8880 8880 tcp" | sudo tee -a /usr/local/bin/natpmp.sh
echo "natpmpc -a 8843 8843 tcp" | sudo tee -a /usr/local/bin/natpmp.sh
echo "natpmpc -a 3478 3478 udp" | sudo tee -a /usr/local/bin/natpmp.sh
# bash /usr/local/bin/natpmp.sh

exit