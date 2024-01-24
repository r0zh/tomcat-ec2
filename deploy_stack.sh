aws cloudformation deploy \
  --template-file ./stack.yml \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_IAM
