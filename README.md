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

**For local development:**
- Docker Desktop
- Docker Compose

**For AWS deployment:**
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
Due to limited time and scope, this implementation is missing several important features that would be expected in a production-ready application.

- No HTTPS:

  - ALB uses HTTP (port 80) instead of HTTPS (port 443).

  - API traffic is unencrypted; SSL/TLS should be added via AWS Certificate Manager.

- No CORS configuration:

  - Backend lacks explicit CORS setup.

  - Works for now since frontend and backend are in the same AWS account, but not best practice for production.

- No custom domains:

  - Uses default AWS-generated URLs for CloudFront and ALB.

  - Production apps should use domains like myapp.com and api.myapp.com.

  - Requires Route 53 domain registration, hosted zone, ALB & CloudFront updates, and SSL certificates.

- No CI/CD pipeline:

  - Deployments are fully manual (docker build, docker push, s3 sync, etc.).

  - Manual workflow is slow, error-prone, and inconsistent.

  - CI/CD should automate builds, tests, ECR pushes, ECS updates, S3 sync, CloudFront invalidation.

- No persistent storage:

  - Backend uses static/hardcoded data.

  - Needs integration with RDS or DynamoDB, backend DB logic, and secure credentials via Secrets Manager.

### Non-Idealities

There are several aspects of the current implementation that could be improved. 

- High fixed ALB cost:

  - ALB costs ~$20/month regardless of traffic.

  - Low-traffic apps could be cheaper on API Gateway + Lambda, though ALB works well for containers.

- Weak security configuration:

  - ALB SG allows HTTP from anywhere (0.0.0.0/0).

  - Should restrict to CloudFront IP ranges or use AWS WAF.

  - No secrets management or container vulnerability scanning.

- Single ECS task / no scaling:

  - Only one ECS task running may lead to single point of failure.

  - No auto-scaling on CPU/memory/requests.

  - Should run multiple tasks across AZs for redundancy.

- Downtime during deployments:

  - Uses force-new-deployment which stops old container before starting the new one.

  - Should use blue-green or rolling deployments for zero-downtime updates.

- Frontend environment variable limitation:

  - VITE_API_BASE_URL must be hardcoded at build time.

  - Requires rebuilding the frontend for each environment (dev/stage/prod).

- Local Terraform state:

  - State stored on disk having risk of corruption, loss, and conflicts.

  - Production should use remote backend with state locking (S3 + DynamoDB).