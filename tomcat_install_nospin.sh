#!/bin/bash

# define log decorations
warn="\033[43m\033[37m\033[1m warn \033[0m"
error="\033[41m\033[37m\033[1m fail \033[0m"
info="\033[44m\033[37m\033[1m info \033[0m"

# check if the script is run as root
if [ "$EUID" -ne 0 ]; then
	echo -e "\033[1;31mthis script needs to be run with sudo. please run it again as root\033[0m"
	exit
fi

create a user called tomcat
# check if the user already exists
if id -u tomcat &>/dev/null; then
	echo -e "\033[1;34muser tomcat already exists. this script will change it group, home directory and login shell. proceed? (y/n)...\033[0m"
	read -r answer
	if [ "$answer" != "${answer#[yy]}" ]; then
		# update the tomcat user home directory and login shell
		mkdir /opt/tomcat
		echo -e "$info created tomcat home directory."
		usermod -m -d /opt/tomcat -s /bin/false tomcat
		echo -e "$info updated tomcat user."
		# add tomcat to the tomcat group
		if grep -q "^tomcat:" /etc/group; then
			echo -e "$info group tomcat already exists. skipping group creation..."
		else
			groupadd tomcat
			echo -e "$info added tomcat group."
		fi
		usermod -a -g tomcat tomcat
		echo -e "$info added tomcat user to tomcat group."
	else
		echo -e "\033[31mexiting.\033[0m"
		exit 1
	fi
else
	useradd -m -d /opt/tomcat -s /bin/false tomcat
	echo -e "$info \033[1;32mcreated tomcat user.\033[0m"
fi

# update the package manager cache
echo -e "$info updating package manager cache..."
apt update >/dev/null 2>&1

# install the jdk
echo -e "$info installing jdk-17..."
apt install openjdk-17-jdk -y >/dev/null 2>&1

# navigate to the /tmp directory
cd /tmp

# download tomcat using curl
for i in {1..4}; do
	echo -e "$info downloading tomcat..."
	curl -s -o tomcat.tar.gz https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.18/bin/apache-tomcat-10.1.18.tar.gz >/dev/null 2>&1
	# check if the file is downloaded
	if [ -f tomcat.tar.gz ]; then
		echo -e "$info downloaded tomcat"
		break
	elif [ $i -ne 4 ]; then
		echo -e "$warn attempt $i failed! trying again..."
		sleep 2
	elif [ ! -f tomcat.tar.gz ] && [ $i -eq 4 ]; then
		echo -e "$error failed to download tomcat after 3 attempts. exiting."
		exit 1
	fi
done

# extract tomcat to /opt/tomcat
echo -e "$info extracting tomcat..."
(tar xzvf tomcat.tar.gz -c /opt/tomcat --strip-components=1 >/dev/null 2>&1)
if [ $? -eq 0 ]; then
	echo -e "$info extracted tomcat"
else
	echo -e "$error failed to extract tomcat"
	exit 1
fi

# grant tomcat ownership over the extracted installation
chown -r tomcat:tomcat /opt/tomcat/
chmod -r u+x /opt/tomcat/bin

echo -e "$info \033[1;32minstaled tomcat\033[0m"

# subtitutes tomcat-users closing tag with a role tag
sed -i '/<\/tomcat-users>/c\<role rolename="manager-gui" \/>' /opt/tomcat/conf/tomcat-users.xml
# adds the rest of the role tags
echo '<user username="manager" password="manager_password" roles="manager-gui" />' >>/opt/tomcat/conf/tomcat-users.xml
echo '<role rolename="admin-gui" />' >>/opt/tomcat/conf/tomcat-users.xml
echo '<user username="admin" password="admin_password" roles="manager-gui,admin-gui" />' >>/opt/tomcat/conf/tomcat-users.xml
# closes the tomcat-users tag
echo '</tomcat-users>' >>/opt/tomcat/conf/tomcat-users.xml

echo -e "$info configured tomcat-users.xml"

# remove the restriction for the manager and host manager page by commenting out remoteaddrvalve
sed -i '/<valve classname="org.apache.catalina.valves.remoteaddrvalve"/c\<!-- <valve classname="org.apache.catalina.valves.remoteaddrvalve"' /opt/tomcat/webapps/manager/meta-inf/context.xml
sed -i '/allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/>/c\allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/> -->' /opt/tomcat/webapps/manager/meta-inf/context.xml
sed -i '/<valve classname="org.apache.catalina.valves.remoteaddrvalve"/c\<!-- <valve classname="org.apache.catalina.valves.remoteaddrvalve"' /opt/tomcat/webapps/host-manager/meta-inf/context.xml
sed -i '/allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/>/c\allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/> -->' /opt/tomcat/webapps/host-manager/meta-inf/context.xml

echo -e "$info removed restriction for the manager and host manager page"

# store the java_home path in a variable
java_home=$(update-java-alternatives -l | tr -s ' ' | cut -d' ' -f3)

# create a systemd service file for tomcat
touch /etc/systemd/system/tomcat.service

# define the contents of the service file
content=$(
	cat <<eof
[unit]
description=tomcat
after=network.target

[service]
type=forking

user=tomcat
group=tomcat

environment="java_home=$java_home"
environment="java_opts=-djava.security.egd=file:///dev/urandom"
environment="catalina_base=/opt/tomcat"
environment="catalina_home=/opt/tomcat"
environment="catalina_pid=/opt/tomcat/temp/tomcat.pid"
environment="catalina_opts=-xms512m -xmx1024m -server -xx:+useparallelgc"

execstart=/opt/tomcat/bin/startup.sh
execstop=/opt/tomcat/bin/shutdown.sh

restartsec=10
restart=always

[install]
wantedby=multi-user.target
eof
)

# add the content to the service file
echo "$content" >/etc/systemd/system/tomcat.service

echo -e "$info created tomcat.service file"

# reload the systemd daemon
systemctl daemon-reload

# start the tomcat service
systemctl start tomcat >/dev/null 2>&1
if [ $? -eq 0 ]; then
	echo -e "$info started tomcat service"
else
	echo -e "$error failed to start tomcat service"
	exit 1
fi

# enable the tomcat service to start on boot
systemctl enable tomcat >/dev/null 2>&1
if [ $? -eq 0 ]; then
	echo -e "$info enabled tomcat service"
else
	echo -e "$error failed to enable tomcat service"
	exit 1
fi

# check if the tomcat service is active
if systemctl is-active --quiet tomcat; then # if the service is active (returns 0)
	echo -e "$info \033[1;32mserver is running at port 8080 🚀 \033[0m"
else # if the service is not active (returns 3)
	echo -e "$error something went wrong"
fi
