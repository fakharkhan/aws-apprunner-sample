# Deploy to AWS App Runner - Step by Step Guide

## ✅ Deployment Complete!

**Service Status**: Deployed and running  
**Service URL**: `https://pmghbtdqp2.eu-central-1.awsapprunner.com`  
**Service ARN**: `arn:aws:apprunner:eu-central-1:899735862078:service/aws-apprunner-sample/8a2138917ec04213b1d36f1be2e472f2`

### ✅ Completed Steps
- ✅ Docker image built and tested locally
- ✅ Image pushed to ECR: `899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest`
- ✅ APP_KEY generated: `base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s=`
- ✅ App Runner service created via AWS CLI
- ✅ Health check configured at `/health`

## 🚀 Create App Runner Service via Console

### Step 1: Open App Runner Console
1. Go to [AWS App Runner Console](https://console.aws.amazon.com/apprunner/home?region=eu-central-1#/services)
2. Make sure you're in region: **eu-central-1**
3. Click **Create service**

### Step 2: Configure Source and Deployment
1. Select **Container registry** → **Amazon ECR**
2. **Container image URI**: 
   ```
   899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest
   ```
3. **Deployment trigger**: Select **Automatic** (deploys when image is updated)
4. Click **Next**

### Step 3: Configure Build Settings
1. **Port**: `8000`
2. **Environment variables** - Add the following:
   - `APP_ENV` = `production`
   - `APP_DEBUG` = `false`
   - `APP_KEY` = `base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s=`
   - `LOG_CHANNEL` = `stderr`
3. Click **Next**

### Step 4: Configure Service
1. **Service name**: `aws-apprunner-sample`
2. **Virtual CPU**: `1 vCPU`
3. **Memory**: `2 GB`
4. Click **Next**

### Step 5: Configure Health Check (IMPORTANT!)
1. **Health check protocol**: Select **HTTP**
2. **Health check path**: `/health`
3. **Health check interval**: `10` seconds
4. **Health check timeout**: `5` seconds
5. **Healthy threshold**: `1`
6. **Unhealthy threshold**: `5`
7. Click **Next**

### Step 6: Review and Create
1. Review all settings
2. **Auto scaling**: Leave default (or adjust if needed)
3. Click **Create & deploy**

### Step 7: Wait for Deployment
- The service will take 5-10 minutes to deploy
- Monitor the deployment in the **Logs** tab
- Once status shows **Running**, your service is live!

## 📋 Service Details

After deployment, you'll get:
- **Service URL**: `https://<service-id>.eu-central-1.awsapprunner.com`
- **Default domain**: Provided in the service overview

## 🔧 Post-Deployment Configuration

### Update APP_URL
Update the `APP_URL` environment variable with your service URL:
1. Go to [App Runner Console](https://console.aws.amazon.com/apprunner/home?region=eu-central-1#/services)
2. Click on your service: `aws-apprunner-sample`
3. Go to **Configuration** tab
4. Click **Edit** in **Configure service** section
5. Add environment variable:
   - `APP_URL` = `https://pmghbtdqp2.eu-central-1.awsapprunner.com`
6. Click **Save changes** (this will trigger a new deployment)

**Or use AWS CLI:**
```bash
aws apprunner update-service \
  --service-arn "arn:aws:apprunner:eu-central-1:899735862078:service/aws-apprunner-sample/8a2138917ec04213b1d36f1be2e472f2" \
  --source-configuration '{
    "ImageRepository": {
      "ImageIdentifier": "899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest",
      "ImageConfiguration": {
        "Port": "8000",
        "RuntimeEnvironmentVariables": {
          "APP_ENV": "production",
          "APP_DEBUG": "false",
          "APP_KEY": "base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s=",
          "LOG_CHANNEL": "stderr",
          "APP_URL": "https://pmghbtdqp2.eu-central-1.awsapprunner.com"
        }
      },
      "ImageRepositoryType": "ECR"
    },
    "AutoDeploymentsEnabled": true,
    "AuthenticationConfiguration": {
      "AccessRoleArn": "arn:aws:iam::899735862078:role/service-role/AppRunnerECRAccessRole"
    }
  }' \
  --region eu-central-1
```

## ✅ Verify Deployment

Check deployment status:
```bash
cd deployment
./check-deployment.sh
```

Or test your endpoints directly:

```bash
# Test health endpoint
curl https://pmghbtdqp2.eu-central-1.awsapprunner.com/health

# Test root endpoint
curl https://pmghbtdqp2.eu-central-1.awsapprunner.com/
```

Expected health response:
```json
{
  "status": "healthy",
  "timestamp": "2025-12-02T...",
  "service": "aws-apprunner-sample",
  "database": "connected"
}
```

## 📊 Monitor Your Service

- **Logs**: Service → **Logs** tab
- **Metrics**: Service → **Metrics** tab (CPU, Memory, Requests)
- **Events**: Service → **Events** tab (deployment history)

## 🔄 Update Deployment

To update your application:
1. Make changes to your code
2. Rebuild and push to ECR:
   ```bash
   cd deployment
   ./push-to-ecr.sh
   ```
3. App Runner will automatically detect the new image and deploy (if Auto-deploy is enabled)

## 🆘 Troubleshooting

### Service won't start
- Check **Logs** tab for errors
- Verify environment variables are set correctly
- Ensure health check path `/health` is accessible

### Health check failing
- Verify `/health` endpoint returns 200 status
- Check health check configuration matches your app

### Image pull errors
- Verify ECR repository exists and image is pushed
- Check App Runner service role has ECR permissions

## 📝 Quick Reference

**ECR Repository**: `softpyramid/aws-apprunner-sample`  
**Region**: `eu-central-1`  
**Image URI**: `899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest`  
**Port**: `8000`  
**Health Check Path**: `/health`

