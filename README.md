# Tomcat EC2 Setup

This repository contains scripts and configuration files for setting up Apache Tomcat on an Amazon EC2 instance.

## Files

### `tomcat_install.sh`

This is a shell script that automates the installation and configuration of Apache Tomcat on a Linux system. It performs the following tasks:

- Creates a user named `tomcat`.
- Installs OpenJDK-17.
- Downloads and extracts Apache Tomcat.
- Configures manager and admin users.
- Sets up a Tomcat systemd service.

To run the script, execute the following command:

```bash
sudo bash tomcat_install.sh
```


### `stack.yml`

This is a CloudFormation template for creating an EC2 instance and a security group in AWS. The security group allows incoming traffic on ports 8080 and 22.

## Usage

1. Clone this repository.
2. Create a CloudFormation stack using the `stack.yml` template.
3. SSH into the EC2 instance.
4. Run the `tomcat_install.sh` script.
