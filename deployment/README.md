# Deployment Scripts and Configuration

This folder contains all deployment-related scripts and configuration files for AWS App Runner.

## Files

### Scripts
- **`push-to-ecr.sh`** - Builds and pushes Docker image to Amazon ECR
- **`check-deployment.sh`** - Checks the status of the App Runner service and tests endpoints
- **`update-aws-credentials.sh`** - Helper script to update AWS credentials

### Configuration
- **`apprunner-service-config.json`** - App Runner service configuration (used for creating/updating the service)

### Documentation
- **`DEPLOY_TO_AWS.md`** - Step-by-step guide for deploying to AWS App Runner
- **`DEPLOYMENT.md`** - General deployment documentation

## Usage

### Push Docker Image to ECR
```bash
cd deployment
./push-to-ecr.sh
```

### Check Deployment Status
```bash
cd deployment
./check-deployment.sh
```

### Create/Update App Runner Service
```bash
cd deployment
aws apprunner create-service --cli-input-json file://apprunner-service-config.json --region eu-central-1
```

## Notes

- All scripts assume they are run from the `deployment/` directory
- The `push-to-ecr.sh` script automatically changes to the project root to build the Docker image
- Make sure AWS credentials are configured before running any deployment scripts

