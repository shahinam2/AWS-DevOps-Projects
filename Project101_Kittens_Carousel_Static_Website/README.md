# Project 101: Kittens Carousel Static Website

This project demonstrates how to deploy a static website on an AWS EC2 instance using AWS CloudFormation. The website features a carousel of kitten images and is hosted on an Apache web server.

## Project Structure
```
├── CFN-Template.yaml  # CloudFormation template for deploying the resources
├── README  
└── static-website/  
    └── index.html  # HTML file for the static website
```

## Prerequisites
- AWS CLI installed and configured with appropriate permissions.
- An existing key pair in the AWS region where the stack will be deployed. make sure to replace the `shahin-key` parameter in the CloudFormation template with the name of your key pair.
- Make to change the region in the AWS CLI commands to the region where you want to deploy the stack.
- SSM parameter `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2` available for the latest Amazon Linux 2 AMI.

## Deployment Steps
1. **Create the CloudFormation Stack**
   Use the following command to create the stack:
   ```sh
   aws cloudformation create-stack --stack-name my-stack --template-body file://CFN-Template.yaml --region <your-region>
   ```
2. **Check the Status of the Stack**
   Use the following command to check the status of the stack:
   ```sh
   aws cloudformation describe-stacks --stack-name my-stack --region <your-region>
   ```
3. **Access the Website**
   Once the stack is created successfully, you can access the website using the DNS address of the EC2 instance in the output section of the stack.

4. **Update the Stack**
   To update the stack, use the following command:
   ```sh
   aws cloudformation update-stack --stack-name my-stack --template-body file://CFN-Template.yaml --region <your-region>
   ```




