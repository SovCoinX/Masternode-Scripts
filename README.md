# Masternode-Scripts

Intuitive script for setting up a masternode on Ubuntu 16.04 VPS.

Run these two lines on the vps, and follow instructions.

wget https://github.com/SovCoinX/Masternode-Scripts/raw/master/sov-mn-setup.sh
bash sov-mn-setup.sh


In your local wallet, create a receive address called MN1, and send 15000 SOV in one transaction to the new address.

Open the Masternode Configuration File from Settings.

In tools > Console run this command:
masternode output
This will give you the collateral_output_txid and collateral_output_index for the transaction.

Create a new line like the example in the file,  with your vps IP, port 11888, masternode private key from the vps script, and above collateral_outputs. Finished line should look like this:
MN1 127.0.0.2:11888 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0

Activate the masternode tab in Settings > Advanced Settings
Restart your local wallet to show Masternodes tab
Start your masternode from Masternode tab

Enjoy!

Any questions visit SOV discord at https://discord.gg/y8xXxDG
