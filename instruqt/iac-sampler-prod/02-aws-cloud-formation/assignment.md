---
slug: aws-cloud-formation
id: 2qhdo03bxkum
type: challenge
title: Deploy with Cloud Formation
teaser: Organize deployment assets in a central registry
notes:
- type: text
  contents: Create a template that describes all the AWS resources, and CloudFormation
    takes care of provisioning and configuring those resources for you
tabs:
- title: Code Editor
  type: code
  hostname: cloud-client
  path: /root/terraform
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

1- Set up metadata
===

```bash
# 1.1 - Get the prefix for the naming convention
export PREFIX="ec2-cli-demo-${RANDY}"
```

```bash
# 1.2 - Determine target operating environment and
export LATEST_UR=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=*minimal*hvm-ssd*focal*20*-amd64*2023*" \
  --query 'sort_by(Images, &CreationDate)[].Name' \
  | jq -r '.[length-1]')
```

```bash
# 1.3 - Obtain the AWS AMI ID to create a new EC2 instance
export IMAGE_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=${LATEST_UR}" \
  --query 'sort_by(Images, &CreationDate)[].ImageId' \
  | jq -r '.[]')
```

```bash
# 1.4 - Obtain the unique ID for the default security group
export AWS_DEFAULT_SG=$(aws ec2 describe-security-groups \
--group-name $PREFIX \
| jq -r '.SecurityGroups[].GroupId')
```

```bash
# 1.5 - Get the default subnet ID from the last EC2 Instance
export LATEST_EC2_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=image-id,Values=${IMAGE_ID}" \
  --filters "Name=instance-type,Values=t2.micro" \
  --filters "Name=key-name,Values=${PREFIX}" \
  --filters "Name=instance.group-id,Values=${AWS_DEFAULT_SG}" \
  --filters "Name=instance.group-name,Values=${PREFIX}")

# 1.6 - Since each working environment is configured within
# two or more availability zones, we want to ensure all of
# the work is located within the same subnet.
export SUBNET_ID=$(echo $LATEST_EC2_INSTANCE \
  | jq -r '.[] | .[] | .Instances | .[].SubnetId')
```

---

```bash
# 1.7 - Setup CloudFormation Template
cat << EOF > /root/EC2_Template.json
{
	"AWSTemplateFormatVersion": "2010-09-09",
	"Resources": {
		"EC2Instance": {
			"Type": "AWS::EC2::Instance",
			"Properties": {
				"InstanceType": "t2.nano",
				"ImageId": "${IMAGE_ID}",
				"KeyName": "${PREFIX}",
				"NetworkInterfaces": [{
					"AssociatePublicIpAddress": "true",
					"DeviceIndex": "0",
					"GroupSet": ["$AWS_DEFAULT_SG"],
					"SubnetId": "${SUBNET_ID}"
				}],
				"Tags": [{
					"Key": "Name",
					"Value": "ec2-cf-tpl-${RANDY}"
				}],
				"BlockDeviceMappings": [{
						"DeviceName": "/dev/sdm",
						"Ebs": {
							"VolumeType": "io1",
							"Iops": "200",
							"DeleteOnTermination": "false",
							"VolumeSize": "20"
						}
					},
					{
						"DeviceName": "/dev/sdk",
						"NoDevice": {}
					}
				]
			}
		}
	},
	"Outputs": {
		"InstanceId": {
			"Description": "InstanceId of the newly created EC2 instance",
			"Value": {
				"Ref": "EC2Instance"
			}
		},
		"AZ": {
			"Description": "Availability Zone of the newly created EC2 instance",
			"Value": {
				"Fn::GetAtt": ["EC2Instance", "AvailabilityZone"]
			}
		},
		"PublicDNS": {
			"Description": "Public DNSName of the newly created EC2 instance",
			"Value": {
				"Fn::GetAtt": ["EC2Instance", "PublicDnsName"]
			}
		},
		"PublicIP": {
			"Description": "Public IP address of the newly created EC2 instance",
			"Value": {
				"Fn::GetAtt": ["EC2Instance", "PublicIp"]
			}
		}
	}
}
EOF
```

2- Deploy Cloud Formation Template
===

```bash
# 2.1 - Using the CloudFormation template, create
# a CloudFormation Stack to deploy the EC2 instance
aws cloudformation create-stack \
  --stack-name "CF-TEMPLATE-${RANDY}" \
  --template-body file:///root/EC2_Template.json
```

```bash
# 2.2 - Show the outputs from the CloudFormation Stack
aws cloudformation describe-stacks \
  --stack-name "CF-TEMPLATE-${RANDY}"

# 2.3- To obtain the public IP for the CloudFormation Stack
# deployment, let's be more concrete using JQ
aws cloudformation describe-stacks \
  --stack-name "CF-TEMPLATE-${RANDY}" \
  | jq -r '.[] | .[].Outputs | .[] | select(.OutputKey == "PublicIP") | .OutputValue'

# 2.4 - Assign the public IP to a variable
export EC2_INSTANCE_IP=$(aws cloudformation describe-stacks \
  --stack-name "CF-TEMPLATE-${RANDY}" \
  | jq -r '.[] | .[].Outputs | .[] | select(.OutputKey == "PublicIP") | .OutputValue')

# 2.5 - From the local command line, execute a script
# remotely via SSH to build the Web server content
ssh -o UserKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=no \
  -i "/root/${PREFIX}.pem" \
  ubuntu@$EC2_INSTANCE_IP < /root/bash/deploy-app.sh

# 2.6 - This is our Web server IP
export URL="http://${EC2_INSTANCE_IP}"

# 2.7 - Follow the link to see the payload
echo $URL
```

To complete this challenge, press **Check**.
