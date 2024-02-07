#!/bin/bash

# build the app
cd app/
./gradlew clean war

mv build/libs/app.war /opt/tomcat/webapps/app.war
