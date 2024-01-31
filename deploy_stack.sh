#!/bin/bash
stack_name=$(yq '.stackName' config.yml | tr -d '"')
aws cloudformation deploy \
	--template-file ./stack.yml \
	--stack-name tomcat \
	--capabilities CAPABILITY_IAM
if [ $? -eq 0 ]; then
	aws cloudformation list-exports \
		--query "Exports[?Name=='TomcatURL'].Value"
fi
