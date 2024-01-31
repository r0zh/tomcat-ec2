#!/bin/bash

# define log decorations
warn="\033[43m\033[37m\033[1m warn \033[0m"
error="\033[41m\033[37m\033[1m fail \033[0m"
info="\033[44m\033[37m\033[1m info \033[0m"

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
	echo -e "\033[1;31mThis script needs to be run with sudo. Please run it again as root\033[0m"
	exit
fi

# Create a user called tomcat
# Check if the user already exists
if id -u tomcat &>/dev/null; then
	echo -e "\033[1;34mUser tomcat already exists. This script will change it group, home directory and login shell. Proceed? (Y/n)...\033[0m"
	read -r answer
	if [ "$answer" != "${answer#[Yy]}" ]; then
		# Update the tomcat user home directory and login shell
		mkdir /opt/tomcat
		echo -e "$info Created tomcat home directory."
		usermod -m -d /opt/tomcat -s /bin/false tomcat
		echo -e "$info Updated tomcat user."
		# Add tomcat to the tomcat group
		if grep -q "^tomcat:" /etc/group; then
			echo -e "$info Group tomcat already exists. Skipping group creation..."
		else
			groupadd tomcat
			echo -e "$info Added tomcat group."
		fi
		usermod -a -G tomcat tomcat
		echo -e "$info Added tomcat user to tomcat group."
	else
		echo -e "\033[31mExiting.\033[0m"
		exit 1
	fi
else
	useradd -m -d /opt/tomcat -s /bin/false tomcat
	echo -e "$info \033[1;32mCreated tomcat user.\033[0m"
fi

# Update the package manager cache
echo -e "$info Updating package manager cache..."
apt update >/dev/null 2>&1

# Install the jdk
echo -e "$info Installing JDK-17..."
apt install openjdk-17-jdk -y >/dev/null 2>&1

# Navigate to the /tmp directory
cd /tmp

# Download tomcat using curl
for i in {1..4}; do
	echo -e "$info Downloading tomcat..."
	curl -s -o tomcat.tar.gz https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.18/bin/apache-tomcat-10.1.18.tar.gz >/dev/null 2>&1
	# Check if the file is downloaded
	if [ -f tomcat.tar.gz ]; then
		echo -e "$info Downloaded tomcat"
		break
	elif [ $i -ne 4 ]; then
		echo -e "$warn Attempt $i failed! Trying again..."
		sleep 2
	elif [ ! -f tomcat.tar.gz ] && [ $i -eq 4 ]; then
		echo -e "$error Failed to download tomcat after 3 attempts. Exiting."
		exit 1
	fi
done

# Extract tomcat to /opt/tomcat
echo -e "$info Extracting tomcat..."
(tar xzvf tomcat.tar.gz -C /opt/tomcat --strip-components=1 >/dev/null 2>&1)
if [ $? -eq 0 ]; then
	echo -e "$info Extracted tomcat"
else
	echo -e "$error Failed to extract Tomcat"
	exit 1
fi

# Grant tomcat ownership over the extracted installation
chown -R tomcat:tomcat /opt/tomcat/
chmod -R u+x /opt/tomcat/bin

echo -e "$info \033[1;32mInstaled tomcat\033[0m"

# Define privileged users in Tomcat’s configuration
# Subtitutes tomcat-users closing tag with a role tag
sed -i '/<\/tomcat-users>/c\<role rolename="manager-gui" \/>' /opt/tomcat/conf/tomcat-users.xml
# Adds the rest of the role tags
echo '<user username="manager" password="manager_password" roles="manager-gui" />' >>/opt/tomcat/conf/tomcat-users.xml
echo '<role rolename="admin-gui" />' >>/opt/tomcat/conf/tomcat-users.xml
echo '<user username="admin" password="admin_password" roles="manager-gui,admin-gui" />' >>/opt/tomcat/conf/tomcat-users.xml
# Closes the tomcat-users tag
echo '</tomcat-users>' >>/opt/tomcat/conf/tomcat-users.xml

echo -e "$info Configured tomcat-users.xml"

# Remove the restriction for the Manager and Host Manager page by commenting out RemoteAddrValve
sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/c\<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i '/allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/>/c\allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/> -->' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/c\<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sed -i '/allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/>/c\allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/> -->' /opt/tomcat/webapps/host-manager/META-INF/context.xml

echo -e "$info Removed restriction for the Manager and Host Manager page"

# Store the JAVA_HOME path in a variable
java_home=$(update-java-alternatives -l | tr -s ' ' | cut -d' ' -f3)

# Create a systemd service file for Tomcat
touch /etc/systemd/system/tomcat.service

# Define the contents of the service file
content=$(
	cat <<EOF
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=$java_home"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
)

# Add the content to the service file
echo "$content" >/etc/systemd/system/tomcat.service

echo -e "$info Created tomcat.service file"

# Reload the systemd daemon
systemctl daemon-reload

# Start the Tomcat service
systemctl start tomcat >/dev/null 2>&1
if [ $? -eq 0 ]; then
	echo -e "$info Started tomcat service"
else
	echo -e "$error Failed to start Tomcat service"
	exit 1
fi

# Enable the Tomcat service to start on boot
systemctl enable tomcat >/dev/null 2>&1
if [ $? -eq 0 ]; then
	echo -e "$info Enabled tomcat service"
else
	echo -e "$error Failed to enable Tomcat service"
	exit 1
fi

# Check if the Tomcat service is active
if systemctl is-active --quiet tomcat; then # if the service is active (returns 0)
	echo -e "$info \033[1;32mServer is running at port 8080 🚀 \033[0m"
else # if the service is not active (returns 3)
	echo -e "$error Something went wrong"
fi

