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

#Prerequisites
clear
echo Prerequisites: Checking if you are running as root...
idinfo=$(id -u)
if [[ idinfo -eq 0 ]]
  then
    echo 'You are running as root! :-)'
else
  echo 'You are not running as root :-('
  echo This script has to run in SUDO mode to run smoothly!
  exit
fi

#Wi-Fi connection configuration
echo Wi-Fi connection Configuration
echo -n 'Do you want to configure your Wi-Fi connection? [Y/n] '
read wificonnectiondecision

if [[ $wificonnectiondecision =~ (Y|y) ]]
  then
    echo -n 'Your SSID: '
    read  wifissid
    echo -n 'Your Password: '
    read wifipassword
    wpa_passphrase "$wifissid" "$wifipassword" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf
    wpa_cli -i wlan0 reconfigure
    echo 'Wi-Fi connection configured!'
elif [[ $wificonnectiondecision =~ (n) ]]
  then
    echo No modifications was made
    echo You can visit https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md to setup your Wi-Fi connection later.
else
    echo Invalid imput!
    echo You can visit https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md to setup your Wi-Fi connection later.
fi

#Checking Memory Requirements
clear
echo Step 1: Checking minimum system memory requirements...
memtotal=$(cat /proc/meminfo | grep MemTotal | grep -o '[0-9]*')
swaptotal=$(cat /proc/meminfo | grep SwapTotal | grep -o '[0-9]*')
echo Your total system memory is $memtotal
echo Your total system swap is $swaptotal
totalmem=$(($memtotal + $swaptotal))
echo Your effective total system memory is $totalmem

if [[ $totalmem -lt 900000 ]]
  then
    echo You have insufficient memory to install Ubiquiti UniFi Controller, minimum 1 GB
    echo -n 'Do you want to create a 1 G swap file? [Y/n] '
    read swapfiledecision
      if [[ $swapfiledecision =~ (Y|y) ]]
        then
          echo 'Creating 1 G swap file...'
            sudo fallocate -l 1G /swapfile
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
            sudo cp /etc/fstab /etc/fstab.bak
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
          echo '1 G swap file successfully created!'
      elif [[ $swapfiledecision =~ (n) ]]
        then
          echo No swap file was created!
          echo Insufficient memory to install Ubiquiti UniFi Controller
          echo Exiting...
          exit
      else
        echo Input error!
        echo No swap file was created!
        echo Please start again
        echo Exiting...
        exit
      fi
else
  echo 'You have enough memory to meet the requirements! :-)'
fi

#Installing Ubiquiti UniFi Controller
clear
echo Step 2: Installing Ubiquiti UniFi Controller...
sudo apt-get install gnupg1 apt-transport-https dirmngr -y
echo 'deb https://www.ubnt.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/ubnt-unifi.list
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ubnt.com/unifi/unifi-repo.gpg
sudo apt-get update && sudo apt-get install unifi haveged certbot fail2ban traceroute glances python3-pip iperf3 lynx miniupnpc dnsutils -y
sudo pip3 install --upgrade glances
#sudo apt-get install default-jre-headless -y
#sudo service unifi restart
#sleep 10

#Configure Ubiquiti UniFi Controller Java Memory (heap size) Allocation
clear
echo Step 3: Advanced settings
echo 'Default Ubiquiti UniFi Controller Java memory allocation (heap size)'
echo Maximum memory allocation: 1024 MB
echo 'Default settings is suitable for almost all use cases, modify ONLY IF NEEDED (large installs, etc.)!'
echo Reboot may be required after modifications!
echo -n 'Do you want to modify the memory allocation for Ubiquiti UniFi Controller? [Y/n] '
read modifymemoryallocationdecision

if [[ $modifymemoryallocationdecision =~ (Y|y) ]]
  then
    echo -n 'How much for maximum memory allocation (heap size) (Minimum Size: 1024 MB)? '
    read maximummemoryallocationdecision
      if [[ $maximummemoryallocationdecision -ge 1024 ]]
        then
          cd /usr/lib/unifi/data
          cat system.properties > /dev/null
          echo '# Modifications' | sudo tee -a /usr/lib/unifi/data/system.properties
          echo unifi.xms=256 | sudo tee -a /usr/lib/unifi/data/system.properties
          echo unifi.xmx="$maximummemoryallocationdecision" | sudo tee -a /usr/lib/unifi/data/system.properties
          sudo service unifi restart
      else
        echo 'Your input is lower than the requirement to run Ubiquiti UniFi Controller (1024 MB)!'
        echo No modifications was made
        cd /usr/lib/unifi/data
        cat system.properties > /dev/null
        echo '# Modifications' | sudo tee -a /usr/lib/unifi/data/system.properties > /dev/null
        echo unifi.xms=256 | sudo tee -a /usr/lib/unifi/data/system.properties
        echo unifi.xmx=1024 | sudo tee -a /usr/lib/unifi/data/system.properties
      fi
elif [[ $modifymemoryallocationdecision =~ (n) ]]
  then
    echo No modifications was made
    cd /usr/lib/unifi/data
    cat system.properties > /dev/null
    echo '# Modifications' | sudo tee -a /usr/lib/unifi/data/system.properties > /dev/null
    echo unifi.xms=256 | sudo tee -a /usr/lib/unifi/data/system.properties
    echo unifi.xmx=1024 | sudo tee -a /usr/lib/unifi/data/system.properties
else
    echo Invalid imput!
    echo No modifications was made
    cd /usr/lib/unifi/data
    cat system.properties > /dev/null
    echo '# Modifications' | sudo tee -a /usr/lib/unifi/data/system.properties > /dev/null
    echo unifi.xms=256 | sudo tee -a /usr/lib/unifi/data/system.properties
    echo unifi.xmx=1024 | sudo tee -a /usr/lib/unifi/data/system.properties
fi

#Custom SSL Configuration
echo unifi.https.sslEnabledProtocols=TLSv1.2 | sudo tee -a /usr/lib/unifi/data/system.properties
echo unifi.https.ciphers=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256 | sudo tee -a /usr/lib/unifi/data/system.properties

#Enabling High Performance Java Garbage Collector
echo unifi.G1GC.enabled=true | sudo tee -a /usr/lib/unifi/data/system.properties

#Redirect port 443 to 8443
sudo iptables -t nat -I PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443
sudo iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080

#Installing iptables-persistent
sudo apt-get install iptables-persistent -y

sudo service unifi restart

#Downloading Cloudflare DDNS Script
sudo wget https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns_modified-uuc.sh -O /home/cloudflare_ddns_modified-uuc.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/cloudflare/master/cloudflare_ddns_modified-uuc.sh -o /home/cloudflare_ddns_modified-uuc.sh

#Downloading Let's Encrypt Script
sudo wget https://raw.githubusercontent.com/jacktooandroid/ubiquitiunificontroller/personal/unifi_LE_ssl.sh -O /home/unifi_LE_ssl.sh
sudo curl https://raw.githubusercontent.com/jacktooandroid/ubiquitiunificontroller/personal/unifi_LE_ssl.sh -o /home/unifi_LE_ssl.sh

#MiniUPNP Settings
echo "sudo upnpc -r 3478 udp" | sudo tee -a /home/miniupnp.sh
echo "sudo upnpc -r 6789 tcp" | sudo tee -a /home/miniupnp.sh
echo "sudo upnpc -r 8080 tcp" | sudo tee -a /home/miniupnp.sh
echo "sudo upnpc -r 8443 tcp" | sudo tee -a /home/miniupnp.sh
echo "sudo upnpc -r 8880 tcp" | sudo tee -a /home/miniupnp.sh
echo "sudo upnpc -r 8843 tcp" | sudo tee -a /home/miniupnp.sh
sudo bash /home/miniupnp.sh

echo 'Your Ubiquiti UniFi Controller has been installed & modified to your preference (if any)!'
echo 'Share this with others if this script has helped you!'
echo '#UbiquitiEverywhere'
exit