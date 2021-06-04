#!/bin/bash

while :
do

DYNHOST=next.cloud.exige.lu
DYNHOST=${DYNHOST:0:28}
DYNIP=$(host $DYNHOST | grep -iE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" |cut -f4 -d' '|head -n 1)

# Exit if invalid IP address is returned
case $DYNIP in
0.0.0.0 )
exit 1 ;;
255.255.255.255 )
exit 1 ;;
esac

# Exit if IP address not in proper format
if ! [[ $DYNIP =~ (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]) ]]; then
exit 1
fi


sudo ufw allow from $DYNIP to any port 5901
sudo ufw allow from $DYNIP to any port 5902
sudo ufw allow from $DYNIP to any port 5903
sudo ufw allow from $DYNIP to any port 5904
sudo ufw allow from $DYNIP to any port 5905
sudo ufw allow from $DYNIP to any port 5906
sudo ufw allow from $DYNIP to any port 5907
sudo ufw allow from $DYNIP to any port 5908

echo renew IP: $DYNIP
sleep 600
done
