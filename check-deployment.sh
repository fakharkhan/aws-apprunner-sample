#!/bin/bash

# App Runner Service Details
SERVICE_ARN="arn:aws:apprunner:eu-central-1:899735862078:service/aws-apprunner-sample/8a2138917ec04213b1d36f1be2e472f2"
SERVICE_URL="https://pmghbtdqp2.eu-central-1.awsapprunner.com"
REGION="eu-central-1"

echo "🚀 Checking App Runner Service Status..."
echo "Service URL: ${SERVICE_URL}"
echo ""

# Check service status
STATUS=$(aws apprunner describe-service \
  --service-arn "${SERVICE_ARN}" \
  --region "${REGION}" \
  --query 'Service.Status' \
  --output text 2>/dev/null)

echo "Current Status: ${STATUS}"
echo ""

if [ "$STATUS" = "RUNNING" ]; then
  echo "✅ Service is RUNNING!"
  echo ""
  echo "Testing endpoints..."
  echo ""
  
  echo "1. Health Check:"
  curl -s "${SERVICE_URL}/health" | python3 -m json.tool 2>/dev/null || curl -s "${SERVICE_URL}/health"
  echo ""
  echo ""
  
  echo "2. Root Endpoint:"
  curl -I "${SERVICE_URL}/" 2>&1 | head -5
  echo ""
  
  echo "🎉 Your application is live at: ${SERVICE_URL}"
elif [ "$STATUS" = "OPERATION_IN_PROGRESS" ] || [ "$STATUS" = "CREATE_FAILED" ] || [ "$STATUS" = "UPDATE_FAILED" ]; then
  echo "⏳ Service is still deploying or has issues..."
  echo ""
  echo "View logs in AWS Console:"
  echo "https://console.aws.amazon.com/apprunner/home?region=${REGION}#/services/${SERVICE_ARN}"
  echo ""
  echo "Or check status with:"
  echo "aws apprunner describe-service --service-arn '${SERVICE_ARN}' --region ${REGION}"
else
  echo "Status: ${STATUS}"
  echo "Check AWS Console for details"
fi

