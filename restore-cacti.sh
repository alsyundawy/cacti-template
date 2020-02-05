#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/KnoAll/cacti-template/dev/restore-cacti.sh)

green=$(tput setaf 2)
red=$(tput setaf 1)
tan=$(tput setaf 3)
reset=$(tput sgr0)

printinfo() {
	printf "${tan}::: ${green}%s${reset}\n" "$@"
}

printwarn() {
	printf "${tan}*** WARNING: %s${reset}\n" "$@"
}

printerror() {
	printf "${red}!!! ERROR: %s${reset}\n" "$@"
}

case $(whoami) in
        root)
		printerror "You ran me as root! Do not run me as root!"
		exit 1
		;;
        pi)
		printerror "You ran me as pi user! Do not run me as pi!"
		exit 1
                ;;
        cacti)       
		;;
        *)
		printerror "Uh-oh. You are not logged in as the cacti user. Exiting..."
		exit 1
                ;;
esac

check-cacti() {
# check existing cacti installation
	test -f /var/www/html/cacti/include/cacti_version
	if [ $? -ne 1 ];then
		printinfo "Valid Cacti install found..."
	else
		printerror "Cacti is not already installed, cannot proceed."
		exit 1
	fi
# backup existing cacti data?
	read -p "Do you want to backup existing Cacti install before restoring over top? [y/N] " yn
	case "$yn" in
		y | Y | yes | YES| Yes ) printinfo "Ok, let's go!"
		counter=$( curl -s http://www.kevinnoall.com/cgi-bin/counter/unicounter.pl?name=backup-data&write=0 )
		bash <(curl -s https://raw.githubusercontent.com/KnoAll/cacti-template/master/backup-cacti.sh) $1;;
		* ) 
		printwarn "Skipping backup of existing Cacti."
		;;
	esac
}


# TODO: get file from param - list files for selection?
backupfile=backup_cacti-1.2.3.tar.gz
unpack-check() {
	printinfo "Unpacking backup..."
	tar -xzf ~/$backupfile
		if [ $? -ne 0 ];then
			printerror "Backup unpack error cannot restore, exiting..."
			exit 1
		fi
	restoreFolder=$( find . -type f -name '.cacti-backup' | sed -r 's|/[^/]+$||' |sort |uniq )
		if [ $? -ne 0 ];then
			printerror "Backup file not usable, cannot restore, exiting..."
			exit 1
		fi
	
# check for version to be restored
	restoreVersion=$( cat $restoreFolder/.cacti-backup )
		if [ $? -ne 0 ];then
			printerror "Cannot verify backup for automated restore, exiting..."
			exit 1
		fi
	read -p "Cacti v$restoreVersion found, is that what you want to restore? [y/N] " yn
	case "$yn" in
		y | Y | yes | YES| Yes ) printinfo "Restoring Cacti v$restoreVersion from backup..."
		;;
		* ) 
		printerror "NOT restoring Cacti v$restoreVersion. Exiting..."
		exit 1
		;;
	esac
}

# TODO: dump exiting rra and move backup rra
# TODO: drop/restore mysql cacti db
drop-restore () {
	gunzip $restoreFolder/mysql.cacti_*.sql.gz
	if [ $? -ne 0 ];then
		printerror "Backup db not usable, cannot restore, exiting..."
		exit 1
	else
		sudo mysql -p cacti < $restoreFolder/mysql.cacti_*.sql
		if [ $? -ne 0 ];then
			printerror "Backup db did not restore properly, exiting..."
			exit 1
		fi
	fi
}

# TODO: check for proper file permissions
# TODO: cleaup
# TODO: counter

check-cacti
unpack-check
drop-restore

exit 0
