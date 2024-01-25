stack_name=$(yq '.stackName' config.yml | tr -d '"')
aws cloudformation delete-stack --stack-name $stack_name
