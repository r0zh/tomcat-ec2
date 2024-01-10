#!/bin/bash

# Create a user called tomcat
sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat

# Update the package manager cache
sudo apt update

# Install the JDK
sudo apt install openjdk-17-jdk -y

# Navigate to the /tmp directory
cd /tmp

# Download the archive using wget
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.18/bin/apache-tomcat-10.1.18.tar.gz

# Extract the archive
sudo tar xzvf apache-tomcat-10*.tar.gz -C /opt/tomcat --strip-components=1

# Grant tomcat ownership over the extracted installation
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo chmod -R u+x /opt/tomcat/bin

# Define privileged users in Tomcat’s configuration
echo '<role rolename="manager-gui" />' | sudo tee -a /opt/tomcat/conf/tomcat-users.xml
echo '<user username="manager" password="manager_password" roles="manager-gui" />' | sudo tee -a /opt/tomcat/conf/tomcat-users.xml
echo '<role rolename="admin-gui" />' | sudo tee -a /opt/tomcat/conf/tomcat-users.xml
echo '<user username="admin" password="admin_password" roles="manager-gui,admin-gui" />' | sudo tee -a /opt/tomcat/conf/tomcat-users.xml

# Remove the restriction for the Manager page
sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/c\<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i '/allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/>/c\allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/> -->' /opt/tomcat/webapps/manager/META-INF/context.xml
# Repeat for Host Manager
sed -i '/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/c\<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sed -i '/allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/>/c\allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1" \/> -->' /opt/tomcat/webapps/host-manager/META-INF/context.xml