---
slug: aws-ec2-cli
id: 
type: challenge
title: Create a full stack deployment
teaser: Every product release starts with infrastructure
notes:
- type: text
  contents: You're about to create a simple Web application deployment using the AWS
    CLI to build resources in AWS
tabs:
- title: Cloud CLI
  type: terminal
  hostname: cloud-client
- title: AWS Console
  type: service
  hostname: cloud-client
  path: /
  port: 80
difficulty: basic
timelimit: 5400
---

1 - Align requirements
===

```bash
# 1.1 - What is our identity?
aws sts get-caller-identity
```

```bash
# 1.2 - Confirm we are working in US-EAST-2
aws configure get profile.default.region
```

```bash
# 1.3 - Confirm that we have an assinged VPC
aws ec2 describe-vpcs
```

```bash
# 1.4 - Determine target operating environment
aws ec2 describe-images --owners 099720109477 \
  --filters "Name=name,Values=*minimal*hvm-ssd*focal*20*-amd64*2023*" \
  --query 'sort_by(Images, &CreationDate)[].Name'
```

```bash
# 1.5 - Get AWS AMI ID
aws ec2 describe-images --owners 099720109477 \
  --filters "Name=name,Values=ubuntu-minimal/images/hvm-ssd/ubuntu-focal-20.04-amd64-minimal-20230331" \
  --query 'sort_by(Images, &CreationDate)[].ImageId' | jq -r '.[]'
```

2 - Deploy Infrastructure
===

```bash
# 2.1 - Setup basic prefix for the naming convention
# Welcome Randy (a random number for an ID)
echo $RANDY

# Use a unique identifier for the demo user.
export PREFIX="ec2-cli-demo-${RANDY}"

# 2.2 - Obtain latest release name of Ubuntu Focal
export LATEST_UR=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=*minimal*hvm-ssd*focal*20*-amd64*2023*" \
  --query 'sort_by(Images, &CreationDate)[].Name' \
  | jq -r '.[length-1]')

# 2.3 - Obtain the AWS AMI ID to create a new EC2 instance
export IMAGE_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=${LATEST_UR}" \
  --query 'sort_by(Images, &CreationDate)[].ImageId' \
  | jq -r '.[]')
```

Create deployment

```bash
# 2.4 - Create an EC2 key pair to access the new EC2 instance
aws ec2 create-key-pair \
  --key-name $PREFIX \
  --query 'KeyMaterial' \
  --output text > "${PREFIX}.pem"

# 2.4.1 - Safe permissions for EC2 Key
chmod 400 "${PREFIX}.pem"

# 2.5 - We need to declare an AWS EC2 security group
aws ec2 create-security-group \
--group-name $PREFIX \
--description "EC2 CLI Demo"

# 2.6 - Obtain the unique ID for the new security group
export AWS_DEFAULT_SG=$(aws ec2 describe-security-groups \
--group-name $PREFIX \
| jq -r '.SecurityGroups[].GroupId')

# 2.6.1 - Open HTTP port 22 to the whole world
aws ec2 authorize-security-group-ingress \
--group-id $AWS_DEFAULT_SG \
--protocol tcp \
--port 22 \
--cidr 0.0.0.0/0

# 2.6.2 - Open HTTP port 80 to the whole world
aws ec2 authorize-security-group-ingress \
--group-id $AWS_DEFAULT_SG \
--protocol tcp \
--port 80 \
--cidr 0.0.0.0/0

# 2.7 - Launch a bare bones, free-range, glutten-free
# AWS EC2 instance that identifies as a Web server
export LATEST_EC2_INSTANCE=$(aws ec2 run-instances \
--image-id $IMAGE_ID \
--instance-type t2.micro \
--associate-public-ip-address \
--key-name $PREFIX \
--security-group-ids $AWS_DEFAULT_SG)
```

3- Release application
===

```bash
# 3.1 - Get the internal EC2 ID to add tags
export EC2_INSTANCE_ID=$(echo $LATEST_EC2_INSTANCE \
  | jq -r '.Instances | .[].InstanceId')
```

Tag the new instance with the prefix name.

```bash
# 3.2 Tag the new instance with a proper name
aws ec2 create-tags --resources $EC2_INSTANCE_ID \
--tags Key=Name,Value=$PREFIX && sleep 30
```

Work with the new EC2 instance and expose its public IP:

```bash
# 3.3 - Get the instance IP, while filtering for the
# unique identity of the Web server we built
export EC2_INSTANCE_IP=$(aws ec2 describe-instances \
  --filters "Name=instance-type,Values=t2.micro" \
  --filters "Name=tag:Name,Values=${PREFIX}" \
  --filters "Name=instance-state-name,Values=running" \
  | jq -r '.Reservations | .[].Instances | .[].PublicIpAddress')

# 3.4 - From the local command line, execute a script
# remotely via SSH to build the Web server content
ssh -o UserKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=no \
  -i "/root/${PREFIX}.pem" \
  ubuntu@$EC2_INSTANCE_IP < /root/bash/deploy-app.sh

# 3.5 - This is our Web server IP
export URL="http://${EC2_INSTANCE_IP}"

# 3.6 - Follow the link to see the payload
echo $URL
```

To complete this challenge, press **Check**.
