#!/bin/bash

# cd into the script's directory to ensure we are in the correct place
cd $(dirname "$0")

cd app/
./gradlew clear war

mv build/libs/myapp.war /opt/tomcat/webapps/
