#!/bin/bash

# ECR Repository Details
REGION="eu-central-1"
AWS_ACCOUNT_ID="899735862078"
REPOSITORY_NAME="softpyramid/aws-apprunner-sample"
IMAGE_NAME="aws-apprunner-sample"

# Full repository URI
ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPOSITORY_NAME}"

echo "🚀 Starting Docker image push to ECR..."
echo "Repository: ${ECR_REPOSITORY}"
echo "Region: ${REGION}"
echo ""

# Check AWS credentials first
echo "Step 0: Verifying AWS credentials..."
if ! aws sts get-caller-identity --region ${REGION} >/dev/null 2>&1; then
    echo "❌ AWS credentials are invalid or expired!"
    echo ""
    echo "Please configure valid AWS credentials using one of these methods:"
    echo "  1. Run: aws configure"
    echo "     - Set region to: ${REGION}"
    echo "     - Enter valid Access Key ID and Secret Access Key"
    echo ""
    echo "  2. Or use environment variables:"
    echo "     export AWS_ACCESS_KEY_ID=your-key"
    echo "     export AWS_SECRET_ACCESS_KEY=your-secret"
    echo "     export AWS_DEFAULT_REGION=${REGION}"
    echo ""
    exit 1
fi

echo "✅ AWS credentials verified!"
echo ""

# Step 1: Authenticate Docker with ECR
echo "Step 1: Authenticating Docker with ECR..."
if ! aws ecr get-login-password --region ${REGION} 2>/dev/null | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com 2>/dev/null; then
    echo "❌ Authentication failed. Please check:"
    echo "   - Your AWS credentials have ECR permissions"
    echo "   - The repository exists: ${REPOSITORY_NAME}"
    echo "   - Your region is correct: ${REGION}"
    exit 1
fi

echo "✅ Authentication successful!"
echo ""

# Step 2: Build Docker image
echo "Step 2: Building Docker image..."
docker build -t ${IMAGE_NAME} .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed."
    exit 1
fi

echo "✅ Docker image built successfully!"
echo ""

# Step 3: Tag the image
echo "Step 3: Tagging Docker image..."
docker tag ${IMAGE_NAME}:latest ${ECR_REPOSITORY}:latest

if [ $? -ne 0 ]; then
    echo "❌ Docker tag failed."
    exit 1
fi

echo "✅ Docker image tagged successfully!"
echo ""

# Step 4: Push the image
echo "Step 4: Pushing Docker image to ECR..."
docker push ${ECR_REPOSITORY}:latest

if [ $? -ne 0 ]; then
    echo "❌ Docker push failed."
    exit 1
fi

echo "✅ Docker image pushed successfully!"
echo ""
echo "🎉 Your image is now available at: ${ECR_REPOSITORY}:latest"

