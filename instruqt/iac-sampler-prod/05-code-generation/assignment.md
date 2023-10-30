---
slug: code-generation
id: rozn8yynl6wm
type: challenge
title: Code Generation
teaser: Use Aritficial Intelligence to generate IaC.
notes:
- type: text
  contents: Replace this text with your own text
tabs:
- title: Code Editor
  type: code
  hostname: cloud-client
  path: /root
- title: Cloud CLI
  type: terminal
  hostname: cloud-client
- title: AWS Console
  type: service
  hostname: cloud-client
  path: /
  port: 80
difficulty: ""
timelimit: 600
---
1- Setup Resources
===
Install Pulumi
```bash
cd /root
curl -fsSL https://get.pulumi.com | sh
```
Confirm deployment
```bash
pulumi version
```

2 - Write AI prompt
===
2.1 Visit [Pulumi](https://www.pulumi.com/ai)

2.2 Choose `Python` as the generated language

2.3 Provide the following prompt:

```bash
A static website running on AWS, with an EC2 instance
exposing an HTTPS connection via an Internet Gateway,
and retrieving a  package from a GitHub release.
```
3 - Execute AI Code
===
# 1.1 - Move to our working directory
```bash
export PULUMI_DIR=/root/pulumi
cd $PULUMI_DIR
```
# Deploy the code
```bash
pulumi up
```