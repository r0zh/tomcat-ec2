#!/bin/bash

# Create a user called tomcat
if id -u tomcat &>/dev/null; then
    echo "User tomcat already exists."
else
    sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
    echo "Added tomcat user successfully."
fi

# Update the package manager cache
sudo apt update

# Install the JDK
sudo apt install openjdk-17-jdk -y

# Navigate to the /tmp directory
cd /tmp

# Download tomcat using wget
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.18/bin/apache-tomcat-10.1.18.tar.gz -O tomcat.tar.gz

# Check if the file is downloaded successfully
if [ ! -f tomcat.tar.gz ]; then
    echo "Failed to download tomcat. Exiting."
    exit 1
fi

# Extract tomcat to /opt/tomcat
sudo tar xzvf tomcat.tar.gz -C /opt/tomcat --strip-components=1

# Grant tomcat ownership over the extracted installation
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo chmod -R u+x /opt/tomcat/bin

# Define privileged users in Tomcat’s configuration
# subtitutes tomcat-users closing tag with a role tag
sed -i '/<\/tomcat-users>/c\<role rolename="manager-gui" \/>' /opt/tomcat/conf/tomcat-users.xml
# adds the rest of the role tags
echo '<user username="manager" password="manager_password" roles="manager-gui" />' | sudo tee -a /opt/tomcat/conf/tomcat-users.xml
echo '<role rolename="admin-gui" />' | sudo tee -a /opt/tomcat/conf/tomcat-users.xml
echo '<user username="admin" password="admin_password" roles="manager-gui,admin-gui" />' | sudo tee -a /opt/tomcat/conf/tomcat-users.xml
# closes the tomcat-users tag
echo '</tomcat-users>' | sudo tee -a /opt/tomcat/conf/tomcat-users.xml

# Remove the restriction for the Manager and Host Manager page by commenting out RemoteAddrValve
sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/c\<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i '/allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/>/c\allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/> -->' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/c\<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sed -i '/allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/>/c\allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/> -->' /opt/tomcat/webapps/host-manager/META-INF/context.xml

# Store the JAVA_HOME path in a variable
java_home=$(update-java-alternatives -l | tr -s ' ' | cut -d' ' -f3)
echo $java_home

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

# Reload the systemd daemon
sudo systemctl daemon-reload

# Start the Tomcat service
sudo systemctl start tomcat

# Enable the Tomcat service to start on boot
sudo systemctl enable tomcat

# Check if the Tomcat service is active
if systemctl is-active --quiet tomcat; then # if the service is active (returns 0)
    echo -e "\033[1;32m Server is running! 🚀 \033[0m"
else # if the service is not active (returns 3)
    echo -e "\033[1;31m Something went wrong! ❌ \033[0m"
fi
