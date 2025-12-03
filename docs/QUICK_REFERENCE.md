# Quick Reference Guide - AWS App Runner Deployment

## 🚀 Quick Commands

### Build and Push to ECR
```bash
cd deployment
./push-to-ecr.sh
```

### Check Deployment Status
```bash
cd deployment
./check-deployment.sh
```

### Test Locally
```bash
docker build -t aws-apprunner-sample:local .
docker run -d -p 8000:8000 \
  -e PORT=8000 \
  -e APP_KEY="base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s=" \
  --name test \
  aws-apprunner-sample:local

curl http://localhost:8000/health
```

### View App Runner Service Status
```bash
aws apprunner describe-service \
  --service-arn "arn:aws:apprunner:eu-central-1:899735862078:service/aws-apprunner-sample/<id>" \
  --region eu-central-1 \
  --query 'Service.Status' \
  --output text
```

### View Service Logs
```bash
aws logs tail "/aws/apprunner/aws-apprunner-sample/<service-id>/service" \
  --region eu-central-1 \
  --since 30m \
  --format short
```

## 📋 Key Information

| Item | Value |
|------|-------|
| **AWS Account** | 899735862078 |
| **Region** | eu-central-1 |
| **ECR Repository** | softpyramid/aws-apprunner-sample |
| **ECR URI** | 899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest |
| **Port** | 8000 |
| **Health Check** | TCP on port 8000 |
| **APP_KEY** | base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s= |
| **IAM Role** | arn:aws:iam::899735862078:role/service-role/AppRunnerECRAccessRole |

## 🔗 Important Links

- **App Runner Console**: https://console.aws.amazon.com/apprunner/home?region=eu-central-1
- **ECR Console**: https://console.aws.amazon.com/ecr/repositories?region=eu-central-1
- **GitHub Repo**: https://github.com/fakharkhan/aws-apprunner-sample

## ⚠️ Current Status

**BLOCKED**: TCP health check failures in App Runner  
**Action Required**: Contact AWS Support

