stack_name=$(yq '.stackName' config.yml)
aws cloudformation delete-stack --stack-name $stack_name
