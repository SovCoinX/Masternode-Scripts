#!/bin/bash
# Sovereign masternode Setup Script V0.1 for Ubuntu 16.04.05 LTS
# (c) 2018 by Cryptominer937 for Sovereign Coin
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash sov-mn-setup.sh 
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#Sovereign TCP port
PORT=11888
#Function detect_ubuntu
 if [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
else
   echo -e "${RED}You are not running Ubuntu 16.04, Installation is cancelled.${NC}"
   exit 1
fi

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'sovd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop sovd${NC}"
        sov-cli stop
        delay 30
        if pgrep -x 'sovd' > /dev/null; then
            echo -e "${RED}sovd daemon is still running!${NC} \a"
            echo -e "${YELLOW}Attempting to kill...${NC}"
            pkill sovd
            delay 30
            if pgrep -x 'sovd' > /dev/null; then
                echo -e "${RED}Can't stop sovd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1

clear
echo -e "${YELLOW}Sovereign masternode Setup Script V1.7 for Ubuntu 16.04 LTS${NC}"
echo "Do you want me to generate a masternode private key for you? [y/n]"
  read DOSETUP
if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a" 
else 
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
#kill Daemon
cd ~
pkill ./sovd
pkill sovd
cd SovereignMasternodeSetup

#Check Deps
if [ -d "/var/lib/fail2ban/" ]; 
then
    echo -e "${GREEN}Dependencies already installed...${NC}"
else
    echo -e "${GREEN}Updating system and installing required packages...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev
sudo apt-get install unzip
sudo apt-get -y install libminiupnpc-dev
sudo apt-get -y install fail2ban
sudo service fail2ban restart
sudo apt-get install libdb5.3++-dev libdb++-dev libdb5.3-dev libdb-dev && ldconfig
sudo apt-get install -y unzip libzmq3-dev build-essential libssl-dev libboost-all-dev libqrencode-dev libminiupnpc-dev libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5
   fi

#Network Settings
echo -e "${GREEN}Installing Network Settings...${NC}"
{
sudo apt-get install ufw -y
} &> /dev/null
echo -ne '[##                 ]  (10%)\r'
{
sudo apt-get update -y
} &> /dev/null
echo -ne '[######             ] (30%)\r'
{
sudo ufw default deny incoming
} &> /dev/null
echo -ne '[#########          ] (50%)\r'
{
sudo ufw default allow outgoing
sudo ufw allow ssh
} &> /dev/null
echo -ne '[###########        ] (60%)\r'
{
sudo ufw allow $PORT/tcp
sudo ufw allow $RPC/tcp
} &> /dev/null
echo -ne '[###############    ] (80%)\r'
{
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
} &> /dev/null
echo -ne '[#################  ] (90%)\r'
{
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"
} &> /dev/null
echo -ne '[###################] (100%)\n'

#Generating Random Password for sovd JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
#if grep -q "SwapTotal" /proc/meminfo; then
if grep -q "swapfile" /etc/fstab; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 /var/swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${RED}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi

#Installing Daemon
cd ~
mkdir ~/SovereignMasternodeSetup/sov
sudo rm sov-Linux64-V1.2.1
wget https://github.com/SovCoinX/SovCoin/releases/download/2.0.1/sov-mn-2.0.1-ubuntu.tar.gz
tar xzf sov-mn-2.0.1-ubuntu.tar.gz -C ~/SovereignMasternodeSetup/sov
rm -r sov-mn-2.0.1-ubuntu.tar.gz
stop_daemon

# Deploy binaries to /usr/bin
sudo cp SovereignMasternodeSetup/sov/sov* /usr/bin/
sudo chmod 755 -R ~/SovereignMasternodeSetup
sudo chmod 755 /usr/bin/sov*

# Deploy masternode monitoring script
cp ~/SovereignMasternodeSetup/sovmon.sh /usr/local/bin
sudo chmod 711 /usr/local/bin/sovmon.sh

#Create datadir
if [ ! -f ~/.sovcore/sov.conf ]; then 
	sudo mkdir ~/.sovcore
   cd ~/.sovcore
        #TODO wget https://transfer.sh/14JiW1/bootstrap.dat
   cd ~
	
fi

echo -e "${YELLOW}Creating sov.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.sovcore/sov.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.sovcore/sov.conf
 
    #Starting daemon first time just to generate masternode private key
    sovd --daemon
    sleep 30

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(sov-cli masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR: Can not generate masternode private key.${NC} \a"
        echo -e "${RED}ERROR: Reboot VPS and try again or supply existing genkey as a parameter.${NC}"
        exit 1
    fi
    
    #Stopping daemon to create sov.conf
    stop_daemon
    delay 30
fi

# Create sov.conf
cat <<EOF > ~/.sovcore/sov.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=64
txindex=1
masternode=1
externalip=$publicip:$PORT
masternodeprivkey=$genkey
addnode=23.138.32.32:11888
addnode=154.16.7.176:11888
addnode=192.99.19.133:11888
addnode=172.96.162.204:11888
addnode=149.248.2.163:11888
addnode=80.211.139.49:11888
addnode=140.82.61.148:11888
addnode=174.138.10.106:11888
EOF

#Finally, starting Sovereign daemon with new sov.conf
cd ~
sovd --daemon
delay 5

#Setting auto star cron job for daemon
cronjob="@reboot sleep 30 && sovd --daemon"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "${GREEN}Configuring crontab job...${NC}"
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron

echo -e "========================================================================
${YELLOW}masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${YELLOW}$publicip${NC}
Masternode Private Key: ${YELLOW}$genkey${NC}
Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your Sovereign collateral funds):
======================================================================== \a"
echo -e "${YELLOW}mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}masternode.conf${NC} file and replace:
    ${YELLOW}mn1${NC} - with your desired masternode name (alias)
    ${YELLOW}TxId${NC} - with Transaction Id from masternode outputs
    ${YELLOW}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the Sovereign network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'IsSynced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in masternode list${NC}, which is normal and expected.
2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}masternode start-alias mn1${NC}
    where ${YELLOW}vn1${NC} is the name of your masternodenode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    masternodes -> Select masternode -> RightClick -> ${YELLOW}start alias${NC}
Once completed step (2), return to this VPS console and wait for the
masternode Status to change to: 'masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!
Currently your vrnode is syncing with the Sovereign network...
The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in sov.conf:
${YELLOW}cat ~/.sovcore/sov.conf${NC}
Here is your sov.conf generated by this script:
-------------------------------------------------${YELLOW}"
cat ~/.sovcore/sov.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit sov.conf, first stop the Sovereigncoiond daemon,
then edit the sov.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the sovd daemon back up:
to stop:   ${YELLOW}./sov-cli stop${NC}
to edit:   ${YELLOW}nano ~/.sovcore/sov.conf${NC}
to start:  ${YELLOW}./sovd${NC}
========================================================================
To view sovd debug log showing all MN network activity in realtime:
${YELLOW}tail -f ~/.sovcore/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:
${YELLOW}htop${NC}
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the sovmon.sh script:
${YELLOW}sovmon.sh${NC}
or just type 'node' and hit <TAB> to autocomplete script name.
========================================================================
Enjoy your Sovereign masternode and thanks for using this setup script!
If you found it helpful, please donate Sovereign to:
SS88ux4JUXF6vrzsBkz7Jm6XV5s9qJWU3i
...and make sure to check back for updates!
"

# EOF