#!/bin/bash
stack_name=$(yq '.stackName' config.yml | tr -d '"')
aws cloudformation deploy \
  --template-file ./stack.yml \
  --stack-name tomcat \
  --capabilities CAPABILITY_IAM
