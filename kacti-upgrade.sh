#!/bin/bash

if [[ `whoami` == "root" ]]; then
    echo "You ran me as root! Do not run me as root!"
    exit 1
fi

if [ -f ~/kacti-upgrade.sh ]
then
	echo ""
else
	echo "Downloading kacti-upgrade.sh"
  wget https://raw.githubusercontent.com/KnoAll/cacti-template/master/kacti-upgrade.sh
exit 1
fi

if [ -f ~/.kacti-template ]
then
	echo "Found preexisting Kacti-template Install, proceeding to upgrade..."
	echo ""
  bash <(curl -s https://raw.githubusercontent.com/KnoAll/cacti-template/master/update-git.sh)
else
	echo "Cacti is not already installed, sorry cannot upgrade. Exiting..."
    sleep 5
    exit 1
fi


