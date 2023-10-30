---
slug: create-terraform-module
id: 
type: challenge
title: Create a Terraform Module
teaser: Comoditize component delivery with Terraform modules, in a producer-to-consumer
  alignment
notes:
- type: text
  contents: Modules are self-contained packages of Terraform configurations that are
    managed as a group
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
timelimit: 600
---
1- Deploy multiple resources with a Terraform Module
===
```bash
# 1.1 - Move to our working directory
export TF_DIR=/root/terraform/02
cd $TF_DIR

# 1.2 - Create ["une", "deux", "trois"] instances
# using a the reusable `aws_ec2_instance` module
terraform init
terraform plan
terraform apply -auto-approve
```

2- Safely store the Terraform state
===

2.1 - Create the AWS S3 bucket

```bash
# 2.1.1 - Move to our working directory
export TF_DIR=/root/terraform/03/aws_s3_bucket
cd $TF_DIR

# 2.1.2 - Create AWS S3 bucket
terraform init
terraform plan
terraform apply -auto-approve
```

2.2 - Obtain the AWS S3 bucket metadata

```bash
# 2.2.1 - Configure working directory:
export TF_DIR=/root/terraform/03/aws_s3_bucket

# 2.2.2 - Configure prefix for deployment:
export PREFIX="$(cd $TF_DIR && terraform output -raw s3_bucket_name)"

# 2.2.3 - Configure optional postfix that matches
# the current deployment:
export POSTFIX=$(echo $RANDY)

# 2.2.4 - Get default AWS region:
export REGION=$(cd $TF_DIR && terraform output -raw s3_bucket_region)
```

2.3 - Generate backend

```bash
cat << EOF > /root/terraform/02/backend.tf
terraform {
  backend "s3" {
    bucket = "${PREFIX}"
    key    = "${POSTFIX}/terraform.tfstate"
    region = "${REGION}"
  }
}
EOF
```

2.4 - Transfer the Terraform State file

```bash
# 2.4.1 - Configure working directory:
export TF_DIR=/root/terraform/02

# 2.4.2 - Use Terraform init to view the TF State:
cd $TF_DIR && terraform init
```
