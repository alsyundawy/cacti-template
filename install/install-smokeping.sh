#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/KnoAll/cacti-template/dev/install-smokeping.sh)

if [[ `whoami` == "root" ]]; then
    echo -e "\033[31m You ran me as root! Do not run me as root!"
    echo -e -n "\033[0m"
    exit 1
elif [[ `whoami` == "cacti" ]]; then
echo ""
elif grep -q "Raspbian GNU/Linux 9" /etc/os-release; then
	echo -e "\033[31m Uh-oh. RaspberryPi is not yet supported. Exiting..."
	exit 1
	if [[ `whoami` != "pi" ]]; then
		echo -e "\033[31m Uh-oh. You are not logged in as the default pi user. Exiting..."
		echo -e -n "\033[0m"
		exit 1
	else
		os_dist=raspbian
		os_name=Raspbian
		webserver=apache2
	fi
elif grep -q "CentOS Linux 7" /etc/os-release; then
	if [[ `whoami` != "cacti" ]]; then
		echo -e "\033[31m Uh-oh. You are not logged in as the default cacti user. Exiting..."
		echo -e -n "\033[0m"
		exit 1
	else
		os_dist=centos
		os_name=CentOS7
		webserver=httpd
	fi
else
echo -e "\033[31m Uh-oh. You are not logged in as the cacti user. Exiting..."
echo -e -n "\033[0m"
exit 1
fi

# get the Smokeping version
upgrade_version=2.006011
prod_version=2.007003
web_version=2.7.3
dev_version=
#smokever=$( /opt/smokeping/bin/smokeping --version )
#if [ $? == 0 ];then
#	echo -e "\033[31m Smokeping is already installed, you will need to upgrade not install from scratch,, exiting..."
#	echo -e -n "\033[0m"
#	exit 1
#fi

echo -e "\033[32m Welcome to Kevin's Smokeping install script!"
echo -e -n "\033[0m"
sudo echo ""

function upgrade-fping () {
                echo -e "\033[32m Checking fping version..."
                echo -e -n "\033[0m"
fping -4 -v > /dev/null 2>&1
if [ $? -ne 0 ];then
                echo -e "\033[31m Upgrading fping..."
                echo -e -n "\033[0m"
	cd
	git clone https://github.com/schweikert/fping.git
	cd fping/
	git checkout master
	./autogen.sh
	./configure --prefix=/usr --enable-ipv4 --enable-ipv6
	sudo make
	sudo make install
	sudo chmod +s /usr/sbin/fping
	cd
	rm -rf fping
else
                echo -e "\033[32m fping version OK, moving on..."
                echo -e -n "\033[0m"
fi
}

function install-smokeping () {
echo -e "\033[32m Beginning Smokeping install..."
echo -e "\033[32m Updating CentOS packages..."
echo -e -n "\033[0m"
cd
sudo yum install -y -q perl-core perl-IO-Socket-SSL perl-Module-Build perl-rrdtool
if [ $? -ne 0 ];then
                echo -e "\033[31m CentOS update error cannot install, exiting..."
                echo -e -n "\033[0m"
		exit 1
else
	echo -e "\033[32m Getting Smokeping..."
	echo -e -n "\033[0m"
	cd
	wget -q https://oss.oetiker.ch/smokeping/pub/smokeping-$web_version.tar.gz
	if [ $? -ne 0 ];then
                echo -e "\033[31m Smokeping download error cannot install, exiting..."
                echo -e -n "\033[0m"
		exit 1
	else
	tar -xzf smokeping-$web_version.tar.gz
		if [ $? -ne 0 ];then
                	echo -e "\033[31m Smokeping unpack error cannot install, exiting..."
                	echo -e -n "\033[0m"
			exit 1
		else
			echo -e "\033[32m Setting up Smokeping..."
			echo -e -n "\033[0m"
			#sudo systemctl stop smokeping.service
			#sudo mv /opt/smokeping /opt/smokeping_$smokever
			rm smokeping-$web_version.tar.gz
			cd smokeping-$web_version
			./configure --prefix=/opt/smokeping
			make install -s
			cd
			rm -rf smokeping-$web_version
			mkdir /opt/smokeping/var
			mkdir /opt/smokeping/data			
			mkdir /opt/smokeping/htdocs/cache
			update-config
			#ln -s /var/www/smokeping /opt/smokeping/htdocs/
			#cp /opt/smokeping/htdocs/smokeping.fcgi.dist /opt/smokeping/htdocs/smokeping.cgi
			update-permissions
			chmod 620 /opt/smokeping/etc/smokeping_secrets.dist
			echo -e "\033[32m Restarting services..."
			echo -e -n "\033[0m"
			wget -q https://raw.githubusercontent.com/KnoAll/cacti-template/dev/install/smokeping-init.d
			sudo mv smokeping-init.d /etc/init.d/smokeping			
			sudo chmod +x /etc/init.d/smokeping
			wget -q https://raw.githubusercontent.com/KnoAll/cacti-template/dev/install/smokeping.conf
			sudo mv smokeping.conf /etc/httpd/conf.d/smokeping.conf
			#sudo systemctl start smokeping.service && sudo systemctl restart httpd.service

			
		fi
	fi
fi
}

function update-config () {
echo -e "\033[32m Updating Smokeping config..."
echo -e -n "\033[0m"
if [ -f  /opt/smokeping/etc/config ]; then
	 sudo sed -i 's/smokeping\/cache/smokeping\/htdocs\/cache/g' /opt/smokeping/etc/config
else
	wget -q https://raw.githubusercontent.com/KnoAll/cacti-template/dev/install/smokeping.config
	mv smokeping.config /opt/smokeping/etc/config
fi
}


function update-permissions () {
bash <(curl -s https://raw.githubusercontent.com/KnoAll/cacti-template/dev/update-permissions-smokeping.sh)
}

update-permissions
upgrade-fping
install-smokeping
update-permissions
counter=$( curl -s http://www.kevinnoall.com/cgi-bin/counter/unicounter.pl?name=smokeping-install-$os_dist&write=0 )
echo ""
echo ""
counter=$( curl -s http://www.kevinnoall.com/cgi-bin/counter/unicounter.pl?name=smokeping-install-$prod_version&write=0 )
echo ""
echo ""
echo -e "\033[32m Installed Smokeping v$prod_version at http://../smokeping/smokeping.cgi Proceed to the web interface..."
echo -e -n "\033[0m"
exit 0
