# MuchToDo – AWS Infrastructure and Deployment

## 1. Project Overview

This project provisions AWS infrastructure using Terraform and deploys the MuchToDo Go backend application using Docker Compose.

### Architecture

The infrastructure consists of:

- VPC with public and private subnets.
- Internet Gateway and NAT Gateway.
- Application Load Balancer (ALB).
- Bastion EC2 instance in a public subnet.
- Backend EC2 instance in a private subnet.
- MongoDB EC2 instance, if required by the infrastructure configuration.
- Security Groups controlling communication between resources.
- Amazon S3 remote backend for Terraform state storage.

The backend application and MongoDB are containerized and managed using Docker Compose on the backend EC2 instance, as specified by the application deployment requirement.

## 2. Prerequisites

Ensure the following tools are installed on your local machine:

| Tool | Purpose |
|---|---|
| Git | Source code management |
| Terraform | Infrastructure provisioning |
| AWS CLI v2 | AWS authentication and management |
| SSH client | Connecting to EC2 instances |
| Docker | Building and running containers locally, if needed |

You will also need:

- An active AWS account.
- AWS IAM Identity Center access.
- Appropriate AWS permissions.
- An SSH key pair for EC2 access.
- Access to the MuchToDo backend repository.

## 3. AWS Authentication

This project uses AWS IAM Identity Center for authentication.

Configure your AWS CLI SSO profile:

```bash
aws configure sso
```

Log in:

```bash
aws sso login --profile terraform-admin
```

Verify your identity:

```bash
aws sts get-caller-identity --profile terraform-admin
```

Ensure the correct AWS account and region are selected.

## 4. Provisioning Infrastructure

### Step 1: Clone the infrastructure repository

```bash
git clone <TERRAFORM_REPOSITORY_URL>
cd <TERRAFORM_REPOSITORY>
```

### Step 2: Configure Terraform variables

Create your Terraform variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update the values according to your AWS environment.

Do not commit `terraform.tfvars` or sensitive credentials to Git.

### Step 3: Initialize Terraform

```bash
terraform init
```

Terraform initializes the AWS provider and connects to the configured S3 remote backend.

### Step 4: Format and validate configuration

```bash
terraform fmt -recursive
terraform validate
```

### Step 5: Review the execution plan

```bash
terraform plan
```

Review the proposed infrastructure changes before applying them.

### Step 6: Provision infrastructure

```bash
terraform apply
```

Review the plan and confirm the operation when prompted.

### Step 7: Retrieve infrastructure outputs

```bash
terraform output
```

Retrieve individual outputs where necessary:

```bash
terraform output alb_dns_name
terraform output bastion_public_ip
terraform output backend_private_ip
```

Use the actual output names defined in the Terraform configuration.

## 5. Connecting to EC2 Instances

The backend EC2 instance is deployed in a private subnet and cannot be accessed directly from the internet.

Access it through the Bastion Host.

### Step 1: Configure SSH access

Ensure your private SSH key has the correct permissions:

```bash
chmod 400 ~/.ssh/startuptech
```

### Step 2: Connect to the Bastion Host

```bash
ssh -i ~/.ssh/startuptech ec2-user@<BASTION_PUBLIC_IP>
```

### Step 3: Connect to the Backend EC2

From your local machine, you can use SSH ProxyCommand:

```bash
ssh -i ~/.ssh/startuptech \
-o IdentitiesOnly=yes \
-o "ProxyCommand=ssh -i ~/.ssh/startuptech -o IdentitiesOnly=yes -W %h:%p ec2-user@<BASTION_PUBLIC_IP>" \
ec2-user@<BACKEND_PRIVATE_IP>
```

## 6. Deploying the Backend Application

### Step 1: Create the application directory

On the backend EC2 instance:

```bash
sudo mkdir -p /opt/much-to-do
sudo chown ec2-user:ec2-user /opt/much-to-do
```

### Step 2: Clone the application repository

```bash
cd /opt/much-to-do

git clone <MUCH_TO_DO_REPOSITORY_URL>
```

Navigate to the backend application directory:

```bash
cd /opt/much-to-do/Server/MuchToDo
```

### Step 3: Configure environment variables

Create the application environment file:

```bash
cp .env.example .env
```

Update the environment variables with the required application configuration.

Do not commit `.env` or expose application secrets.

### Step 4: Build the Docker image

```bash
docker compose up --build -d
```

Docker Compose starts the backend application and MongoDB containers.

### Step 6: Verify container status

```bash
docker compose ps
```

### Step 7: Verify application health

From the backend EC2:

```bash
curl http://localhost:8080/health
```

Expected response:

```json
{
  "cache": "disabled",
  "database": "ok"
}
```

## 7. Accessing the Application

The application is exposed through the Application Load Balancer.

Retrieve the ALB DNS name:

```bash
terraform output alb_dns_name
```

Open the application health endpoint:

```text
http://<ALB_DNS_NAME>/health
```

You should receive an HTTP 200 response when the application is healthy.


Check running containers:

```bash
docker compose ps
```

View application logs:

```bash
docker compose logs -f app
```

Restart the application:

```bash
docker compose restart app
```

Rebuild and deploy updated application code:

```bash
docker compose up --build -d
```

Stop containers without deleting persistent database data:

```bash
docker compose down
```

## 8. Teardown and Cleanup

### Step 1: Stop application containers

Connect to the backend EC2 and navigate to the application directory:

```bash
cd /opt/much-to-do/Server/MuchToDo
```

Stop the containers:

```bash
docker compose down
```

This preserves the named MongoDB data volume.

### Step 2: Destroy AWS infrastructure

Return to your local Terraform repository:

```bash
terraform plan -destroy
```

Review the resources that will be removed.

When ready:

```bash
terraform destroy
```

Confirm the operation when prompted.

**Important:** Destroying the EC2 infrastructure can result in loss of application and database data stored on instance-local storage.

### Step 3: Terraform state cleanup

The Terraform state is stored remotely in the configured S3 bucket.

Do not delete the remote state bucket as part of routine infrastructure teardown. Keep it available for future Terraform operations unless you are intentionally decommissioning the entire project and have safely backed up the state.

## 9. Security Considerations

- SSH access to the Bastion Host is restricted to the administrator's public IP.
- Backend SSH access is allowed only from the Bastion Security Group.
- Backend application traffic is allowed from the ALB Security Group.
- MongoDB access is restricted to the backend where applicable.
- Sensitive configuration values are excluded from Git.
- Terraform state is stored in an encrypted, versioned S3 bucket.
- Public access to the Terraform state bucket is blocked.
- Application containers run using the configured non-root application user.

