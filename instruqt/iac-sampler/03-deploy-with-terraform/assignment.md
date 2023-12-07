---
slug: deploy-with-terraform
id: 
type: challenge
title: Deploy with Terraform
teaser: Use Terraform and the Amazon Web Services (AWS) provider to build resources
notes:
- type: text
  contents: Terraform is an infrastructure as code tool that lets you build, change,
    and version infrastructure safely and efficiently
tabs:
- title: Code Editor
  type: code
  hostname: cloud-client
  path: /root/aws
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
1- Deploy resources with Terraform
===
```bash
# 1.1 - Move to working directory for Terraform exercise 1:
export TF_DIR=/root/terraform/01
cd $TF_DIR
```

```bash
# 1.2 - Use the Terraform command line utility to download the required providers:
terraform init

# 1.2.1 - Show what terraform downloaded and configured
tree -a .
```

```bash
# 1.3 - Examine the changes to the infrastructure based on the plan
terraform plan
```

```bash
# 1.4 - Build the infrastructure
terraform apply -auto-approve
```