# Startup Script Improvements

## Changes Made

Based on the [Dev.to Laravel App Runner article](https://dev.to/massivebrains/deploying-a-laravel-app-on-aws-app-runner-1hmp) and best practices, I've simplified and improved the startup script.

### Key Improvements:

1. **Better Logging**
   - All output redirected to stderr so App Runner can capture it
   - Clear section headers for easier debugging
   - More descriptive log messages

2. **Port Configuration**
   - Dynamically reads PORT from environment variable
   - Updates nginx configuration at runtime
   - Ensures binding to all interfaces (default behavior)

3. **Error Handling**
   - Laravel optimization commands won't crash the container if they fail
   - Critical errors (nginx test failure) will still exit properly
   - Better handling of missing .env.example file

4. **Environment File Creation**
   - Creates minimal .env if .env.example doesn't exist
   - Generates APP_KEY if not provided via environment variable
   - Handles both scenarios gracefully

5. **Nginx Error Logging**
   - Nginx errors now go directly to stderr
   - App Runner will capture these for debugging

## Files Modified

1. `docker/start.sh` - Simplified and improved startup script
2. `docker/nginx.conf` - Nginx errors now log to stderr

## Next Steps

1. **Rebuild and push the Docker image:**
   ```bash
   cd "/Users/fakharkhan/Library/CloudStorage/OneDrive-WOWBrands/Applications/AWS Runner/apprunnersample"
   docker build -t aws-apprunner-sample .
   docker tag aws-apprunner-sample:latest 899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest
   docker push 899735862078.dkr.ecr.eu-central-1.amazonaws.com/softpyramid/aws-apprunner-sample:latest
   ```

2. **Configure App Runner Environment Variables:**
   - Go to App Runner Console → Your Service → Configuration
   - Edit "Configure service"
   - Add environment variables:
     - `APP_ENV=production`
     - `APP_DEBUG=false`
     - `APP_KEY=<your-generated-key>`
     - `LOG_CHANNEL=stderr`

3. **Configure Health Check (Important!):**
   - Go to Configuration → Health check
   - Change from TCP to HTTP health check
   - Health check path: `/up`
   - Protocol: HTTP
   - Port: 8000

4. **Rebuild the service:**
   - Click "Rebuild" button in App Runner Console
   - Monitor the logs to see the improved startup messages

## Testing Locally

Before pushing, you can test locally:

```bash
docker build -t aws-apprunner-sample .
docker run -p 8000:8000 -e PORT=8000 aws-apprunner-sample
```

In another terminal:
```bash
curl http://localhost:8000/up
curl http://localhost:8000
```

## Expected Logs

With the new script, you should see logs like:

```
==========================================
Starting Laravel Application on App Runner
==========================================
PORT environment variable: 8000
Configuring nginx to listen on 0.0.0.0:8000...
Setting Laravel permissions...
Creating .env file...
Generating APP_KEY...
Optimizing Laravel...
Testing nginx configuration...
==========================================
Starting services with Supervisor...
==========================================
```

These logs should now appear in App Runner's application logs!

