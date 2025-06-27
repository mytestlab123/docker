# Testing Container Images

## Available Images

This repository automatically builds and publishes the following container images using Podman/Buildah:

| Folder | Container Image | Description |
|--------|-----------------|-------------|
| `alpine` | `amitkarpe/alpine-demo:latest` | Lightweight Alpine Linux |
| `curl` | `amitkarpe/curl-demo:latest` | cURL container for API testing |

## Quick Start Testing

### Pull and Test All Images
```bash
# Pull all images with Podman
podman pull amitkarpe/alpine-demo:latest
podman pull amitkarpe/curl-demo:latest

# Test each image
podman run --rm amitkarpe/alpine-demo:latest echo "Alpine test"
podman run --rm amitkarpe/curl-demo:latest echo "Curl test"
```

## Detailed Testing Guide

### 1. Alpine Demo Container

**Purpose:** Lightweight Linux with essential tools

```bash
# Run alpine container with Podman
podman run -it --name alpine-test amitkarpe/alpine-demo:latest bash

# Inside container, test tools:
curl --version
wget --version
jq --version

# Test JSON processing
echo '{"name": "test"}' | jq .

# Exit and clean up
exit
podman rm alpine-test
```

**Expected Output:** Minimal container with working tools

### 2. Curl Demo Container

**Purpose:** API testing and HTTP requests

```bash
# Test default behavior (httpbin.org) with Podman
podman run --rm amitkarpe/curl-demo:latest

# Test custom URL
podman run --rm amitkarpe/curl-demo:latest https://api.github.com

# Test JSON API
podman run --rm amitkarpe/curl-demo:latest https://httpbin.org/json

# Test with post data
podman run --rm amitkarpe/curl-demo:latest -X POST https://httpbin.org/post
```

**Expected Output:** JSON responses from APIs

## Advanced Testing Scenarios

### Performance Testing

```bash
# Test container startup time with Podman
time podman run --rm amitkarpe/alpine-demo:latest echo "Speed test"

# Check image sizes
podman images | grep amitkarpe

# Memory usage test
podman stats $(podman run -d amitkarpe/alpine-demo:latest sleep 30)
```

### Network Testing

```bash
# Test container networking with Podman
podman network create test-network

# Test connectivity from curl container
podman run --rm --network test-network amitkarpe/curl-demo:latest https://httpbin.org/json

# Clean up
podman network rm test-network
```

### Volume Testing

```bash
# Test with mounted volumes
mkdir test-data
echo "Hello from host" > test-data/message.txt

# Mount volume in alpine container
podman run --rm -v $(pwd)/test-data:/data amitkarpe/alpine-demo:latest cat /data/message.txt

# Clean up
rm -rf test-data
```

### Security Testing

```bash
# Check if containers run as non-root (Podman runs rootless by default)
podman run --rm amitkarpe/alpine-demo:latest id

# Test resource limits
podman run --rm --memory=64m --cpus=0.5 amitkarpe/alpine-demo:latest echo "Resource limited"

# Check for common vulnerabilities
podman run --rm aquasec/trivy image amitkarpe/alpine-demo:latest
```

## Automated Testing Scripts

### Quick Test All Images
```bash
#!/bin/bash
# test-all-images.sh

IMAGES=("alpine-demo" "curl-demo")

for image in "${IMAGES[@]}"; do
    echo "Testing amitkarpe/${image}:latest..."
    
    if podman run --rm "amitkarpe/${image}:latest" echo "✅ ${image} works"; then
        echo "✅ ${image} test passed"
    else
        echo "❌ ${image} test failed"
    fi
    echo "---"
done
```

### Comprehensive Test Suite
```bash
#!/bin/bash
# comprehensive-test.sh

set -e

echo "🧪 Starting comprehensive Docker image tests..."

# Test 1: Basic functionality
echo "Test 1: Basic functionality"
docker run --rm amitkarpe/nginx-demo:latest nginx -t
docker run --rm amitkarpe/ubuntu-demo:latest curl --version > /dev/null
docker run --rm amitkarpe/alpine-demo:latest jq --version > /dev/null
docker run --rm amitkarpe/curl-demo:latest https://httpbin.org/json > /dev/null

# Test 2: Port binding
echo "Test 2: Port binding"
docker run -d -p 9999:80 --name test-nginx amitkarpe/nginx-demo:latest
sleep 2
curl -f http://localhost:9999 > /dev/null
docker rm -f test-nginx

# Test 3: Interactive mode
echo "Test 3: Interactive capabilities"
echo "exit" | docker run -i amitkarpe/ubuntu-demo:latest bash

echo "✅ All tests passed!"
```

### Performance Benchmark
```bash
#!/bin/bash
# benchmark.sh

IMAGES=("nginx-demo" "ubuntu-demo" "alpine-demo" "curl-demo")

echo "📊 Performance Benchmark"
echo "========================"

for image in "${IMAGES[@]}"; do
    echo "Testing: amitkarpe/${image}:latest"
    
    # Startup time
    start_time=$(date +%s.%N)
    docker run --rm "amitkarpe/${image}:latest" echo "ready" > /dev/null
    end_time=$(date +%s.%N)
    startup_time=$(echo "$end_time - $start_time" | bc)
    
    # Image size
    size=$(docker images "amitkarpe/${image}:latest" --format "{{.Size}}")
    
    echo "  - Startup time: ${startup_time}s"
    echo "  - Image size: ${size}"
    echo "---"
done
```

## Troubleshooting Common Issues

### Image Pull Errors
```bash
# If image pull fails, try:
docker pull amitkarpe/nginx-demo:latest --debug

# Check Docker Hub status
curl -s https://status.docker.com/api/v2/status.json | jq .
```

### Container Won't Start
```bash
# Check logs
docker logs <container-name>

# Run with debug output
docker run --rm -it amitkarpe/nginx-demo:latest sh

# Check image layers
docker history amitkarpe/nginx-demo:latest
```

### Network Issues
```bash
# Test DNS resolution
docker run --rm amitkarpe/curl-demo:latest nslookup google.com

# Check container networking  
docker network ls
docker inspect bridge
```

## Reporting Issues

If you find issues during testing:

1. **Gather Information:**
   ```bash
   docker version
   docker info
   docker logs <container-name>
   ```

2. **Create Minimal Reproduction:**
   ```bash
   # Example reproduction steps
   docker run --rm amitkarpe/problematic-image:latest command-that-fails
   ```

3. **Submit Issue:** Include Docker version, OS, and reproduction steps

## Continuous Integration Testing

These images are tested automatically on every commit. You can also set up local CI testing:

```yaml
# .github/workflows/test-images.yml (example)
name: Test Images
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        image: [nginx-demo, ubuntu-demo, alpine-demo, curl-demo]
    
    steps:
    - name: Test image
      run: |
        docker run --rm amitkarpe/${{ matrix.image }}:latest echo "Testing ${{ matrix.image }}"
```

Happy testing! 🐳✨