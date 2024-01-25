stack_name=$(yq '.stackName' ./config.yml)
aws cloudformation deploy \
  --template-file ./stack.yml \
  --stack-name tomcat \
  --capabilities CAPABILITY_IAM
