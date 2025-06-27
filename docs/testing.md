# Testing Container Images

## Available Images

This repository automatically builds and publishes the following container images using Podman/Buildah to multiple registries:

| Folder | Docker Hub | GitHub Container Registry | Description |
|--------|------------|---------------------------|-------------|
| `alpine` | `amitkarpe/alpine-demo:latest` | `ghcr.io/mytestlab123/alpine-demo:latest` | Lightweight Alpine Linux |
| `curl` | `amitkarpe/curl-demo:latest` | `ghcr.io/mytestlab123/curl-demo:latest` | cURL container for API testing |

## Quick Start Testing

### Pull and Test All Images

**Option 1: Docker Hub (traditional)**
```bash
# Pull from Docker Hub
podman pull amitkarpe/alpine-demo:latest
podman pull amitkarpe/curl-demo:latest

# Test each image
podman run --rm amitkarpe/alpine-demo:latest echo "Alpine test"
podman run --rm amitkarpe/curl-demo:latest echo "Curl test"
```

**Option 2: GitHub Container Registry (no rate limits)**
```bash
# Pull from GHCR (recommended for CI/CD)
podman pull ghcr.io/mytestlab123/alpine-demo:latest
podman pull ghcr.io/mytestlab123/curl-demo:latest

# Test each image
podman run --rm ghcr.io/mytestlab123/alpine-demo:latest echo "Alpine test"
podman run --rm ghcr.io/mytestlab123/curl-demo:latest echo "Curl test"
```

## Detailed Testing Guide

### 1. Nginx Demo Container

**Purpose:** Web server with custom landing page

```bash
# Run nginx container
podman run -d -p 8080:80 --name nginx-test amitkarpe/nginx-demo:latest

# Test the web server
curl http://localhost:8080

# View in browser
open http://localhost:8080

# Clean up
podman stop nginx-test && podman rm nginx-test
```

**Expected Output:** Custom HTML page showing "Nginx Demo Container"

### 2. Ubuntu Demo Container  

**Purpose:** Ubuntu development environment with tools

```bash
# Run ubuntu container interactively
podman run -it --name ubuntu-test amitkarpe/ubuntu-demo:latest bash

# Inside container, test tools:
curl --version
wget --version
vim --version
htop --version

# Exit and clean up
exit
podman rm ubuntu-test
```

**Expected Output:** All tools should be available and show version info

### 3. Alpine Demo Container

**Purpose:** Lightweight Linux with essential tools

```bash
# Run alpine container
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

### 4. Curl Demo Container

**Purpose:** API testing and HTTP requests

```bash
# Test default behavior (httpbin.org)
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
# Test container startup time
time podman run --rm amitkarpe/alpine-demo:latest echo "Speed test"

# Check image sizes
podman images | grep amitkarpe

# Memory usage test
podman stats $(podman run -d amitkarpe/ubuntu-demo:latest sleep 30)
```

### Network Testing

```bash
# Test container networking
podman network create test-network

# Run nginx on custom network
podman run -d --network test-network --name web amitkarpe/nginx-demo:latest

# Test connectivity from curl container
podman run --rm --network test-network amitkarpe/curl-demo:latest http://web

# Clean up
podman rm -f web
podman network rm test-network
```

### Volume Testing

```bash
# Test with mounted volumes
mkdir test-data
echo "Hello from host" > test-data/message.txt

# Mount volume in ubuntu container
podman run --rm -v $(pwd)/test-data:/data amitkarpe/ubuntu-demo:latest cat /data/message.txt

# Clean up
rm -rf test-data
```

### Security Testing

```bash
# Check if containers run as non-root (when applicable)
podman run --rm amitkarpe/ubuntu-demo:latest id

# Test resource limits
podman run --rm --memory=64m --cpus=0.5 amitkarpe/alpine-demo:latest echo "Resource limited"

# Check for common vulnerabilities
podman run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image amitkarpe/nginx-demo:latest
```

## Automated Testing Scripts

### Quick Test All Images
```bash
#!/bin/bash
# test-all-images.sh

IMAGES=("nginx-demo" "ubuntu-demo" "alpine-demo" "curl-demo")

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
podman run --rm amitkarpe/nginx-demo:latest nginx -t
podman run --rm amitkarpe/ubuntu-demo:latest curl --version > /dev/null
podman run --rm amitkarpe/alpine-demo:latest jq --version > /dev/null
podman run --rm amitkarpe/curl-demo:latest https://httpbin.org/json > /dev/null

# Test 2: Port binding
echo "Test 2: Port binding"
podman run -d -p 9999:80 --name test-nginx amitkarpe/nginx-demo:latest
sleep 2
curl -f http://localhost:9999 > /dev/null
podman rm -f test-nginx

# Test 3: Interactive mode
echo "Test 3: Interactive capabilities"
echo "exit" | podman run -i amitkarpe/ubuntu-demo:latest bash

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
    podman run --rm "amitkarpe/${image}:latest" echo "ready" > /dev/null
    end_time=$(date +%s.%N)
    startup_time=$(echo "$end_time - $start_time" | bc)
    
    # Image size
    size=$(podman images "amitkarpe/${image}:latest" --format "{{.Size}}")
    
    echo "  - Startup time: ${startup_time}s"
    echo "  - Image size: ${size}"
    echo "---"
done
```

## Troubleshooting Common Issues

### Image Pull Errors
```bash
# If image pull fails, try:
podman pull amitkarpe/nginx-demo:latest --debug

# Check Docker Hub status
curl -s https://status.docker.com/api/v2/status.json | jq .
```

### Container Won't Start
```bash
# Check logs
podman logs <container-name>

# Run with debug output
podman run --rm -it amitkarpe/nginx-demo:latest sh

# Check image layers
podman history amitkarpe/nginx-demo:latest
```

### Network Issues
```bash
# Test DNS resolution
podman run --rm amitkarpe/curl-demo:latest nslookup google.com

# Check container networking  
podman network ls
podman network inspect podman
```

## Reporting Issues

If you find issues during testing:

1. **Gather Information:**
   ```bash
   podman version
   podman info
   podman logs <container-name>
   ```

2. **Create Minimal Reproduction:**
   ```bash
   # Example reproduction steps
   podman run --rm amitkarpe/problematic-image:latest command-that-fails
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
        podman run --rm amitkarpe/${{ matrix.image }}:latest echo "Testing ${{ matrix.image }}"
```

Happy testing! 🐳✨