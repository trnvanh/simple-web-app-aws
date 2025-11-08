# Simple Web Application

A modern full-stack web application demonstrating cloud-native architecture with React frontend and Node.js backend, deployed on AWS using Infrastructure as Code.

## Architecture

```
┌─────────────────┐    HTTPS    ┌─────────────────┐    HTTPS    ┌─────────────────┐
│   CloudFront    │◄────────────│   Users/Browser │────────────►│   React App     │
│     (CDN)       │             └─────────────────┘             │   (S3 Bucket)   │
└─────────────────┘                                             └─────────────────┘
         │                                                                │
         │ API Calls                                                      │
         ▼                                                                ▼
┌─────────────────┐             ┌─────────────────┐             ┌─────────────────┐
│ Application     │             │   ECS Fargate   │             │   Node.js API   │
│ Load Balancer   │◄───────────►│   Container     │◄───────────►│   (Express)     │
│   (SSL/HTTPS)   │             │   Service       │             │                 │
└─────────────────┘             └─────────────────┘             └─────────────────┘
```

**Tech Stack:**
- **Frontend**: React + Vite → AWS S3 + CloudFront
- **Backend**: Node.js + Express → AWS ECS Fargate
- **Infrastructure**: Terraform (Infrastructure as Code)
- **Monitoring**: CloudWatch + Application Load Balancer


## Project Structure

```
simple_web_app/
├── frontend/
│   ├── src/
│   │   ├── App.jsx          # Main React component
│   │   ├── App.css          # Styling
│   │   └── main.jsx         # Entry point
│   ├── Dockerfile           # Production container
│   ├── package.json         # Dependencies
│   └── vite.config.js       # Build configuration
├── backend/
│   ├── src/
│   │   └── app.js           # Express API server
│   ├── Dockerfile           # Production container
│   └── package.json         # Dependencies
├── iac/
│   ├── main.tf              # Core Terraform config
│   ├── ecs.tf               # ECS Fargate resources
│   ├── frontend.tf          # S3 + CloudFront
│   ├── monitoring.tf        # CloudWatch monitoring
│   ├── variables.tf         # Input variables
│   └── outputs.tf           # Output values
├── docker-compose.yml    # Local development
└── README.md             # This documentation
```

## API Endpoints

| Method | Endpoint     | Description           |
|--------|-------------|-----------------------|
| GET    | `/`          | API information       |
| GET    | `/hello`     | Welcome message       |
| GET    | `/health`    | Health check status   |
| GET    | `/stats`     | Request statistics    |
| GET    | `/api/data`  | Sample JSON data      |


## Quick Start

### Option 1: Local development
```bash
# Clone and run locally
git clone https://github.com/trnvanh/simple-web-app-aws.git
cd simple_web_app
docker-compose up --build

# Access:
# Frontend: http://localhost:8080
# Backend:  http://localhost:3000
```

### Option 2: Deploy to AWS
```bash
# Deploy infrastructure
cd iac
terraform init
terraform plan
terraform apply -auto-approve

# Deploy application (automated via Terraform)
```

## Prerequisites

**For Local Development:**
- Docker Desktop
- Docker Compose

**For AWS Deployment:**
- AWS Account (Free Tier eligible)
- AWS CLI configured
- Terraform >= 1.0

### AWS setup
```bash
# Install tools (macOS)
brew install awscli terraform

# Configure AWS credentials
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Format (json)

# Verify setup
aws sts get-caller-identity
```

## AWS Deployment Guide

### 1. Deploy infrastructure
```bash
cd iac
terraform init
terraform apply -auto-approve
```

### 2. Deploy backend container
```bash
# Get ECR repository URL
ECR_REPO=$(terraform output -raw ecr_repository_url)
ECR_REGISTRY=$(echo $ECR_REPO | cut -d'/' -f1)

# Login to ECR
cd ../backend
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push backend
docker build --platform linux/amd64 -t simple-web-app-backend .
docker tag simple-web-app-backend:latest $ECR_REPO:latest

# Push image
docker push $ECR_REPO:latest

# Force deployment update
aws ecs update-service \
  --cluster simple-web-app-cluster \
  --service simple-web-app-backend-service \
  --force-new-deployment \
  --region us-east-1
```

### 3. Deploy frontend
```bash
cd ../frontend
VITE_API_BASE_URL=https://simple-web-app-alb-1390258519.us-east-1.elb.amazonaws.com

# Build and upload to S3
npm install
npm run build
S3_BUCKET=$(cd ../iac && terraform output -raw s3_bucket_name)
aws s3 sync dist/ s3://$S3_BUCKET --delete

# Invalidate CloudFront cache
DISTRIBUTION_ID=$(cd ../iac && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"

# Test backend endpoints
# For example
curl -k https://simple-web-app-alb-1390258519.us-east-1.elb.amazonaws.com/health
curl -k https://simple-web-app-alb-1390258519.us-east-1.elb.amazonaws.com/hello
```

### 4. Access application
```bash
# Get application URLs
cd iac
echo "Frontend: $(terraform output -raw frontend_url)"
echo "Backend:  $(terraform output -raw backend_api_url)"
```

### 5. Check backend deployment status
```bash
aws ecs describe-services --cluster simple-web-app-cluster --services simple-web-app-backend-service --query "services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}"
```


## Development Commands

**Local development:**
```bash
# Backend development
cd backend && npm install && npm run dev

# Frontend development  
cd frontend && npm install && npm run dev

# Full stack with Docker
docker-compose up --build
```

**AWS management:**
```bash
# Check deployment status
aws ecs describe-services --cluster simple-web-app-cluster \
  --services simple-web-app-backend-service

# View logs
aws logs tail /ecs/simple-web-app-backend --follow

# Update backend image
docker build --platform linux/amd64 -t simple-web-app-backend .
# ... (push steps) ...
aws ecs update-service --cluster simple-web-app-cluster \
  --service simple-web-app-backend-service --force-new-deployment
```

## Troubleshooting

**Common issues:**

1. **AWS credentials error**
   ```bash
   aws configure                    # Re-setup credentials
   aws sts get-caller-identity      # Verify access
   ```

2. **Docker platform issues**
   ```bash
   # Always use AMD64 for AWS ECS
   docker build --platform linux/amd64 -t your-image .
   ```

3. **ECR login issues**
   ```bash
   # Get fresh login token
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin $(ECR_REGISTRY)
   ```

4. **Terraform state issues**
   ```bash
   terraform refresh                # Sync state with AWS
   terraform plan                   # Review changes
   ```

## Clean Up Resources

```bash
# Destroy AWS infrastructure (avoid charges)
cd iac
terraform destroy -auto-approve

# Verify cleanup
aws ecs list-clusters
aws s3 ls | grep simple-web-app
```

## Limitations and Non-Idealities

### Missing parts

**Due to limited time and scope, this implementation is missing several important features that would be expected in a production-ready application.** 
The Application Load Balancer currently uses HTTP on port 80 instead of HTTPS on port 443, which means all **API traffic is transmitted unencrypted and potentially exposes sensitive data.** To add SSL/TLS support, AWS Certificate Manager can be used.

**The backend API lacks explicit CORS configuration,** which could lead to cross-origin request blocking issues when the frontend attempts to communicate with the API in production environments. Although the current setup works because both the frontend and backend are deployed within the same AWS account, this is not a best practice. 

Instead of using a custom domain name, the application relies on **default AWS-generated URLs for both the CloudFront distribution and the Application Load Balancer.** A production application would typically use custom domains like `https://myapp.com` for the frontend and `https://api.myapp.com` for the backend. To implement this, we can register a domain through Route 53, create a hosted zone, and update both the CloudFront distribution and ALB configurations to use the custom domains with SSL certificates.

There is **no automated CI/CD pipeline** in place, which means all deployments must be performed manually using commands like `docker build`, `docker push`, and `aws s3 sync`. This manual process is time-consuming, error-prone, and makes it difficult to maintain consistent deployment practices across team members. A proper CI/CD solution would automate the entire deployment workflow, including building the application, running tests, pushing container images to ECR, updating the ECS service, syncing frontend assets to S3, and invalidating the CloudFront cache.

Finally, **the application lacks any form of persistent data storage.** The backend API currently returns only static, hardcoded data because there is no database integration. For a real application, we can add either Amazon RDS for relational data or DynamoDB for NoSQL data, update the backend code to connect to the database, and store database credentials securely using AWS Secrets Manager. 

### Non-Idealities

There are several aspects of the current implementation that could be improved. **The Application Load Balancer represents a significant fixed cost of approximately $20 per month regardless of how much traffic the application receives.** For applications with low traffic volumes, a serverless architecture using API Gateway and Lambda would be more cost-effective, though the ALB does provide better performance and simpler configuration for containerized applications.

**The security configuration needs improvement in several areas.** The ALB security group currently allows inbound HTTP traffic from any IP address (0.0.0.0/0), which is overly permissive and could be restricted to CloudFront IP ranges or protected by AWS WAF. There is no secrets management system in place for storing sensitive information like API keys or database passwords, and container images are not being scanned for vulnerabilities. 

The current deployment runs only a single ECS task with no auto-scaling configured, which creates a single point of failure and provides no redundancy. **The application cannot automatically scale in response to increased load,** and if the single container fails, the entire backend becomes unavailable. To improve scalability, ECS auto-scaling policies can be configured based on CPU utilization, memory usage, or request count, and run multiple tasks across different availability zones for redundancy.

**The deployment strategy is problematic because it uses the basic `force-new-deployment` command, which stops the old container before starting the new one, causing a brief period of downtime during each deployment.** A better approach would be to use blue-green or rolling deployments that maintain service availability throughout the update process.

The frontend build process requires **the `VITE_API_BASE_URL` environment variable to be hardcoded at build time**, which means you need to rebuild the entire frontend whenever you want to deploy to a different environment (development, staging, or production). 

Lastly, **the Terraform state is stored locally on disk, which creates risks of state file loss and conflicts when multiple developers work on the infrastructure**. If two developers try to apply changes simultaneously, they could corrupt the state file. Production environments should use a remote backend with state locking, which can be implemented using an S3 bucket for storage and a DynamoDB table for locking coordination.