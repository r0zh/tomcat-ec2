# Introduction
This repository contains scripts and configurations for setting up a Tomcat server on an EC2 instance using AWS CloudFormation. The setup includes creating a security group, launching an EC2 instance, and installing Tomcat on the instance.

## Files
Here is a brief overview of the key files in this repository:

#### `stack.yml`: 
This is the AWS CloudFormation template file. It defines the resources needed to set up the Tomcat server, including the security group and the EC2 instance.

#### `tomcat_install.sh`: 
This bash script installs Tomcat on the EC2 instance. It creates a user for Tomcat, updates the package manager cache, installs the Java Development Kit (JDK), downloads and extracts Tomcat, sets up the necessary permissions, and configures Tomcat service.

#### `config.yml`: 
This YAML file stores the name of the CloudFormation stack. It is used by the deploy_stack.sh and delete_stack.sh scripts to identify the stack. Even though it currently only contains one value, it is structured for future scalability.

#### `deploy_stack.sh`: 
This bash script deploys the CloudFormation stack defined in stack.yml. It uses the AWS CLI to create the stack.

#### `delete_stack.sh`: 
This bash script deletes the CloudFormation stack. It uses the AWS CLI to delete the stack.

## Usage
To set up the Tomcat server, follow these steps:
1. Run the `deploy_stack.sh` script to create the CloudFormation stack. This will launch the EC2 instance and apply the security group.
2. SSH into the EC2 instance, clone the tomcat_install.sh script and run it to install Tomcat.
    - ssh -i /path/to/your/key.pem ec2-user@\<instance-ip-address\>
    - git clone https://github.com/r0zh/tomcat-ec2
    - cd tomcat-ec2
    - sudo bash tomcat_install.sh

Once the installation is complete, you can access the Tomcat server by navigating to http://\<instance-ip-address\>:8080 in your web browser.
To delete the CloudFormation stack, run the `delete_stack.sh` script.
