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
