# AWS App Runner Deployment Guide

This guide walks you through deploying your Laravel application to AWS App Runner.

## Prerequisites

Based on the [AWS App Runner Getting Started Guide](https://docs.aws.amazon.com/apprunner/latest/dg/getting-started.html#getting-started.prereq), you need:

### 1. AWS Account Setup
- Complete the setup steps in [Setting up for App Runner](https://docs.aws.amazon.com/apprunner/latest/dg/manage-setup.html)
- Ensure you have appropriate IAM permissions to create App Runner services and ECR repositories

### 2. AWS Resources Required

#### Option A: Deploy from Container Registry (Recommended for Laravel)
- **Amazon ECR (Elastic Container Registry)** - To store your Docker images
- **GitHub Actions** (optional) - For CI/CD automation

#### Option B: Deploy from Source Code Repository
- **GitHub/Bitbucket Connection** - Connected to your AWS account
- **App Runner Configuration File** (`apprunner.yaml`) - For build instructions

### 3. Repository Setup
- Your code is already on GitHub at: `https://github.com/fakharkhan/aws-apprunner-sample`
- Docker files are ready in this repository

## Deployment Steps

### Method 1: Container Registry (ECR) - Recommended

#### Step 1: Create ECR Repository

1. Open the [Amazon ECR Console](https://console.aws.amazon.com/ecr/)
2. Select your region
3. Click **Create repository**
4. Repository name: `aws-apprunner-sample`
5. Click **Create repository**
6. Note the repository URI (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/aws-apprunner-sample`)

#### Step 2: Build and Push Docker Image

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build the image
docker build -t aws-apprunner-sample .

# Tag the image
docker tag aws-apprunner-sample:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/aws-apprunner-sample:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/aws-apprunner-sample:latest
```

#### Step 3: Create App Runner Service

1. Open the [AWS App Runner Console](https://console.aws.amazon.com/apprunner/)
2. Click **Create service**
3. **Source and deployment**:
   - Select **Container registry** → **Amazon ECR**
   - Choose your ECR repository: `aws-apprunner-sample`
   - Image tag: `latest`
   - Deployment trigger: **Automatic** (deploys when image is updated)
4. **Configure build**:
   - Port: `8000`
   - Environment variables:
     - `APP_ENV`: `production`
     - `APP_DEBUG`: `false`
     - `APP_KEY`: (generate one with `php artisan key:generate --show`)
     - `APP_URL`: (will be provided after deployment)
     - `LOG_CHANNEL`: `stderr`
   - Add any other environment variables your app needs (database, etc.)
5. **Configure service**:
   - Service name: `aws-apprunner-sample`
   - CPU: 1 vCPU (or more based on needs)
   - Memory: 2 GB (or more based on needs)
6. Review and **Create & deploy**

#### Step 4: Configure Environment Variables

After the service is created, you can update environment variables:

1. Go to your service → **Configuration** tab
2. Click **Edit** in **Configure service** section
3. Add/update environment variables as needed

### Method 2: Source Code Repository (Alternative)

If you prefer to deploy directly from GitHub:

#### Step 1: Create App Runner Configuration File

Create `apprunner.yaml` in your repository root (already created if using this method):

```yaml
version: 1.0
runtime: dockerfile
build:
  commands:
    build:
      - echo "Building Laravel application..."
run:
  runtime-version: latest
  command: /usr/local/bin/start.sh
  network:
    port: 8000
    env: PORT
  env:
    - name: APP_ENV
      value: production
    - name: APP_DEBUG
      value: "false"
```

#### Step 2: Create App Runner Service from Source

1. Open AWS App Runner Console
2. Click **Create service**
3. **Source and deployment**:
   - Select **Source code repository**
   - Provider: **GitHub**
   - Add connection (if not already connected)
   - Repository: `fakharkhan/aws-apprunner-sample`
   - Branch: `develop` (or `main`)
   - Deployment trigger: **Automatic**
4. **Configure build**:
   - Configuration file: Use `apprunner.yaml`
5. **Configure service**: Same as Method 1
6. **Create & deploy**

## Environment Variables Required

Your Laravel application will need these environment variables configured in App Runner:

### Required
- `APP_ENV`: `production`
- `APP_KEY`: Laravel encryption key (generate with `php artisan key:generate --show`)
- `APP_DEBUG`: `false`
- `APP_URL`: Your App Runner service URL (provided after deployment)

### Optional (if using database)
- `DB_CONNECTION`: `mysql` or `pgsql`
- `DB_HOST`: Your RDS endpoint
- `DB_PORT`: `3306` (MySQL) or `5432` (PostgreSQL)
- `DB_DATABASE`: Your database name
- `DB_USERNAME`: Database username
- `DB_PASSWORD`: Database password

### Optional (if using cache/sessions)
- `CACHE_DRIVER`: `redis` or `file`
- `SESSION_DRIVER`: `redis` or `file`
- `REDIS_HOST`: Redis endpoint (if using Redis)

## Post-Deployment

### 1. Access Your Application
- App Runner provides a default domain: `https://<service-id>.us-east-1.awsapprunner.com`
- You can also configure a custom domain in the **Custom domains** tab

### 2. View Logs
- Go to your service → **Logs** tab
- View application logs, deployment logs, and event logs
- Or view in CloudWatch Logs for more detailed analysis

### 3. Monitor Performance
- Go to **Metrics** tab to view:
  - Requests count
  - Response time
  - CPU/Memory utilization
  - Active instances

## CI/CD Automation (Optional)

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS App Runner

on:
  push:
    branches: [ develop, main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image to Amazon ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: aws-apprunner-sample
          IMAGE_TAG: latest
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
```

## Troubleshooting

### Common Issues

1. **Port Configuration**: Ensure your app listens on the port specified in App Runner (default: 8000)
2. **Environment Variables**: Verify all required env vars are set
3. **Build Failures**: Check build logs in the **Logs** tab
4. **Permission Errors**: Ensure storage and cache directories have correct permissions

### Viewing Logs

```bash
# Via AWS CLI
aws apprunner list-operations --service-arn <service-arn>

# Via Console
# Service → Logs tab → Application logs
```

## Cleanup

To delete your App Runner service:

1. Go to your service → **Actions** → **Delete service**
2. Confirm deletion
3. Optionally delete ECR repository if no longer needed

## Resources

- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [Getting Started Guide](https://docs.aws.amazon.com/apprunner/latest/dg/getting-started.html)
- [Laravel Deployment Guide](https://laravel.com/docs/deployment)

