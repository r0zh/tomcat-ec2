#!/bin/bash

# cd into the script's directory to ensure we are in the correct place
cd $(dirname "$0")

# build the app
cd app/
./gradlew clean war

# copy the app to the tomcat webapps directory
mv build/libs/app.war /opt/tomcat/webapps/app.war
