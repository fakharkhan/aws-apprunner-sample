# DevOps Handover Notes - AWS App Runner Laravel Deployment

**Project**: AWS App Runner Sample (Laravel Application)  
**Repository**: https://github.com/fakharkhan/aws-apprunner-sample  
**Date**: December 3, 2025  
**Status**: ⚠️ **BLOCKED** - Health check failures in App Runner

---

## 📋 Executive Summary

This project is a Laravel application configured for deployment on AWS App Runner. The application builds and runs successfully locally, but deployment to App Runner is currently blocked due to persistent TCP health check failures, even with ultra-minimal test containers.

### Current Status
- ✅ **Local Docker**: Working perfectly
- ✅ **ECR Repository**: Created and accessible
- ✅ **Docker Images**: Building and pushing successfully
- ❌ **App Runner Deployment**: Failing with TCP health check errors
- ⚠️ **Issue**: App Runner cannot connect to port 8000, even with minimal nginx containers

---

## 🏗️ Project Structure

```
apprunnersample/
├── app/                    # Laravel application code
├── docker/                 # Docker configuration files
│   ├── nginx.conf          # Nginx configuration
│   ├── start.sh            # Supervisor-based startup (original)
│   ├── start-minimal.sh    # Minimal nginx+PHP-FPM startup
│   └── start-php-server.sh # PHP built-in server startup
├── deployment/             # Deployment scripts and configs
│   ├── push-to-ecr.sh      # Build and push to ECR
│   ├── check-deployment.sh # Check service status
│   ├── apprunner-service-config.json  # App Runner config
│   └── DEPLOY_TO_AWS.md    # Deployment guide
├── Dockerfile              # Main Dockerfile (uses start-php-server.sh)
├── Dockerfile.ultra-simple  # Ultra-minimal test container
└── routes/web.php          # Laravel routes (includes /health endpoint)
```

---

## 🔧 AWS Resources

### Account Information
- **AWS Account ID**: `899735862078`
- **Region**: `eu-central-1` (Frankfurt)
- **ECR Repository**: `softpyramid/aws-apprunner-sample`
- **ECR URI**: `899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample`

### IAM Roles
- **App Runner Service Role**: `arn:aws:iam::899735862078:role/service-role/AppRunnerECRAccessRole`
  - Required permissions: ECR pull access

### ECR Repository
- **Name**: `softpyramid/aws-apprunner-sample`
- **Image Tag**: `latest`
- **Full URI**: `899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest`

### App Runner Services (Attempted)
Multiple service attempts have been made. Latest service:
- **Service Name**: `aws-apprunner-sample`
- **Latest Service ARN**: `arn:aws:apprunner:eu-central-1:899735862078:service/aws-apprunner-sample/170f764c9c49495cbb9af900a93d9c43`
- **Status**: `CREATE_FAILED`
- **Test Service**: `aws-apprunner-ultra-test` (ultra-minimal nginx container)
- **Test Service ARN**: `arn:aws:apprunner:eu-central-1:899735862078:service/aws-apprunner-ultra-test/73ab34f77e854b1b8ca68a1d40cfd12a`
- **Test Status**: `CREATE_FAILED`

---

## 🚀 Deployment Configuration

### Docker Configuration

**Main Dockerfile** (`Dockerfile`):
- Base: PHP 8.2 FPM with Nginx
- Uses: `start-php-server.sh` (PHP built-in server)
- Port: 8000
- Working locally: ✅ Yes

**Environment Variables** (Set in App Runner):
```bash
PORT=8000
HOSTNAME=0.0.0.0
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s=
LOG_CHANNEL=stderr
```

### App Runner Configuration

**Instance Configuration**:
- CPU: 1 vCPU
- Memory: 2 GB

**Health Check Configuration**:
- Protocol: TCP
- Port: 8000
- Interval: 20 seconds
- Timeout: 10 seconds
- Healthy Threshold: 1
- Unhealthy Threshold: 20 (maximum allowed)

**Source Configuration**:
- Type: ECR
- Image: `899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest`
- Port: 8000
- Auto Deployments: Enabled

---

## 📝 Deployment Process

### 1. Build and Push Docker Image

```bash
cd deployment
./push-to-ecr.sh
```

This script:
- Changes to project root
- Builds Docker image
- Authenticates with ECR
- Tags image as `latest`
- Pushes to ECR

### 2. Create/Update App Runner Service

**Using AWS CLI**:
```bash
cd deployment
aws apprunner create-service \
  --service-name aws-apprunner-sample \
  --source-configuration file://apprunner-service-config.json \
  --instance-configuration '{"Cpu":"1 vCPU","Memory":"2 GB"}' \
  --health-check-configuration '{"Protocol":"TCP","Interval":20,"Timeout":10,"HealthyThreshold":1,"UnhealthyThreshold":20}' \
  --region eu-central-1
```

**Using AWS Console**:
1. Go to [App Runner Console](https://console.aws.amazon.com/apprunner/home?region=eu-central-1)
2. Click "Create service"
3. Select "Container registry" → "Amazon ECR"
4. Enter image URI: `899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest`
5. Configure port: `8000`
6. Add environment variables (see above)
7. Set health check to TCP on port 8000
8. Create service

### 3. Check Deployment Status

```bash
cd deployment
./check-deployment.sh
```

Or manually:
```bash
aws apprunner describe-service \
  --service-arn "arn:aws:apprunner:eu-central-1:899735862078:service/aws-apprunner-sample/<service-id>" \
  --region eu-central-1
```

---

## ⚠️ Current Issues

### Primary Issue: TCP Health Check Failures

**Problem**: All App Runner deployments fail with:
```
Health check failed on protocol `TCP` [Port: '8000']. 
Check your configured port number.
```

**Evidence**:
1. ✅ Containers work perfectly in local Docker
2. ✅ Port 8000 is listening and accessible locally
3. ✅ Ultra-minimal nginx containers also fail
4. ❌ Even simple Alpine + nginx containers fail in App Runner

**What Has Been Tried**:
- ✅ HTTP health checks (failed)
- ✅ TCP health checks (failed)
- ✅ Supervisor-based startup
- ✅ Direct nginx startup
- ✅ PHP built-in server
- ✅ Ultra-minimal nginx containers
- ✅ Increased timeouts (up to 10 seconds)
- ✅ Increased unhealthy threshold (up to 20)
- ✅ Different port configurations
- ✅ Explicit 0.0.0.0 binding

**Conclusion**: This appears to be an App Runner service-level or account-level networking issue, not an application issue.

**📋 Complete Details**: See `docs/HEALTH_CHECK_ATTEMPTS.md` for detailed history of all 5+ attempts with configurations, results, and analysis.

### Test Results

| Container Type | Local Docker | App Runner | Notes |
|---------------|-------------|------------|-------|
| Laravel + Nginx + PHP-FPM (Supervisor) | ✅ Works | ❌ Fails | Original approach |
| Laravel + Nginx + PHP-FPM (Direct) | ✅ Works | ❌ Fails | Minimal startup |
| Laravel + PHP Built-in Server | ✅ Works | ❌ Fails | Simplest Laravel setup |
| Ultra-minimal Nginx (Alpine) | ✅ Works | ❌ Fails | Not Laravel-related |

---

## 🔍 Troubleshooting Guide

### Check Service Status
```bash
aws apprunner describe-service \
  --service-arn "<service-arn>" \
  --region eu-central-1 \
  --query 'Service.Status'
```

### View Service Logs
```bash
aws logs tail "/aws/apprunner/aws-apprunner-sample/<service-id>/service" \
  --region eu-central-1 \
  --since 30m \
  --format short
```

### Test Local Container
```bash
docker build -t aws-apprunner-sample:local .
docker run -d -p 8000:8000 \
  -e PORT=8000 \
  -e APP_KEY="base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s=" \
  --name aws-apprunner-test \
  aws-apprunner-sample:local

# Test health endpoint
curl http://localhost:8000/health

# Check logs
docker logs aws-apprunner-test

# Verify port is listening
docker exec aws-apprunner-test netstat -tlnp | grep 8000
```

### Common Issues

1. **Health Check Failing**
   - Verify container starts correctly locally
   - Check App Runner logs for container startup errors
   - Ensure port 8000 is explicitly configured
   - Try increasing unhealthy threshold

2. **Image Pull Errors**
   - Verify ECR repository exists
   - Check IAM role has ECR permissions
   - Ensure image tag is correct

3. **Container Startup Errors**
   - Check application logs in App Runner console
   - Verify environment variables are set
   - Ensure APP_KEY is provided

---

## 📞 Next Steps & Recommendations

### Immediate Actions Required

1. **Contact AWS Support**
   - **Issue**: TCP health checks failing on port 8000 for all containers
   - **Service ARN**: `arn:aws:apprunner:eu-central-1:899735862078:service/aws-apprunner-ultra-test/73ab34f77e854b1b8ca68a1d40cfd12a`
   - **Evidence**: Even ultra-minimal nginx containers fail
   - **Request**: Investigate App Runner networking/health check mechanism

2. **Verify Account-Level Settings**
   - Check App Runner service quotas
   - Verify VPC/network configuration (if applicable)
   - Review security group settings
   - Check for any account-level restrictions

3. **Alternative Approaches to Consider**
   - Try different AWS region (us-east-1, us-west-2)
   - Use HTTP health checks with longer timeouts
   - Consider ECS Fargate as alternative
   - Review App Runner service limits

### Once Issue is Resolved

1. **Deploy Main Service**
   ```bash
   cd deployment
   ./push-to-ecr.sh
   # Then create service via CLI or console
   ```

2. **Verify Deployment**
   ```bash
   ./check-deployment.sh
   curl https://<service-url>/health
   ```

3. **Set Up Monitoring**
   - Configure CloudWatch alarms
   - Set up log aggregation
   - Configure auto-scaling if needed

---

## 📚 Important Files Reference

### Configuration Files
- `deployment/apprunner-service-config.json` - App Runner service configuration
- `docker/nginx.conf` - Nginx configuration
- `docker/start-php-server.sh` - Current startup script (PHP built-in server)
- `Dockerfile` - Main Dockerfile

### Scripts
- `deployment/push-to-ecr.sh` - Build and push to ECR
- `deployment/check-deployment.sh` - Check deployment status
- `deployment/update-aws-credentials.sh` - Update AWS credentials

### Documentation
- `deployment/DEPLOY_TO_AWS.md` - Step-by-step deployment guide
- `deployment/DEPLOYMENT.md` - General deployment documentation
- `deployment/README.md` - Deployment folder overview
- `docs/DEVOPS_HANDOVER.md` - This file
- `docs/HEALTH_CHECK_ATTEMPTS.md` - **Complete history of all health check attempts**
- `docs/QUICK_REFERENCE.md` - Quick reference guide

---

## 🔐 Security Notes

### Sensitive Information
- **APP_KEY**: `base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s=`
  - Currently in config files (should be moved to secrets manager)
  - Should be rotated in production

### IAM Permissions Required
- ECR: `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`
- App Runner: `apprunner:CreateService`, `apprunner:UpdateService`, `apprunner:DescribeService`
- CloudWatch Logs: `logs:DescribeLogGroups`, `logs:FilterLogEvents`

---

## 📊 Monitoring & Logging

### CloudWatch Logs
- **Log Group**: `/aws/apprunner/aws-apprunner-sample/<service-id>/service`
- **Region**: `eu-central-1`

### View Logs
```bash
aws logs tail "/aws/apprunner/aws-apprunner-sample/<service-id>/service" \
  --region eu-central-1 \
  --since 1h \
  --format short
```

### Metrics to Monitor
- Service status (RUNNING, CREATE_FAILED, etc.)
- Health check success rate
- Container startup time
- Request latency
- Error rates

---

## 🛠️ Development Workflow

### Local Development
```bash
# Build and test locally
docker build -t aws-apprunner-sample:local .
docker run -d -p 8000:8000 \
  -e PORT=8000 \
  -e APP_KEY="base64:wD+4fqUVAkNtJ/zam2Gl2v8EEeZ7+XoLcdnTnQEo94s=" \
  --name aws-apprunner-test \
  aws-apprunner-sample:local

# Test
curl http://localhost:8000/health
curl http://localhost:8000/

# Cleanup
docker stop aws-apprunner-test && docker rm aws-apprunner-test
```

### Deployment Workflow
1. Make code changes
2. Test locally with Docker
3. Build and push to ECR: `./deployment/push-to-ecr.sh`
4. App Runner auto-deploys (if enabled) or manually trigger update
5. Monitor deployment: `./deployment/check-deployment.sh`

---

## 📞 Contact & Support

### Repository
- **GitHub**: https://github.com/fakharkhan/aws-apprunner-sample
- **Branch**: `develop`

### AWS Resources
- **Console**: https://console.aws.amazon.com/apprunner/home?region=eu-central-1
- **ECR Console**: https://console.aws.amazon.com/ecr/repositories?region=eu-central-1

### AWS Support
- **Service**: AWS App Runner
- **Region**: eu-central-1
- **Issue**: TCP health check failures
- **Priority**: High (blocking deployment)

---

## ✅ Checklist for Handover

- [x] Project structure documented
- [x] AWS resources identified
- [x] Deployment process documented
- [x] Current issues documented
- [x] Troubleshooting guide provided
- [x] Security notes included
- [x] Monitoring setup documented
- [x] Next steps identified
- [ ] AWS Support ticket created
- [ ] Alternative deployment method evaluated

---

**Last Updated**: December 3, 2025  
**Prepared By**: Development Team  
**For**: DevOps Team

