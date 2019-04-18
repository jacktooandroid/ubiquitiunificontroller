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
echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/ubnt-unifi.list
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg
sudo apt-get update && sudo apt-get dist-upgrade -y && sudo apt-get install unifi haveged -y

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

echo 'Your Ubiquiti UniFi Controller has been installed & modified to your preference (if any)!'
echo 'Share this with others if this script has helped you!'
echo '#UbiquitiEverywhere'
exit
