# Testing Container Images

## Available Images

This repository automatically builds and publishes container images to multiple registries:

### Standard Images (Docker Workflow)
| Folder | Docker Hub | GHCR | Quay.io | Description |
|--------|------------|------|---------|-------------|
| `alpine` | `amitkarpe/alpine-demo:latest` | `ghcr.io/mytestlab123/alpine-demo:latest` | `quay.io/amitkarpe/alpine-demo:latest` | Lightweight Alpine Linux |
| `curl` | `amitkarpe/curl-demo:latest` | `ghcr.io/mytestlab123/curl-demo:latest` | `quay.io/amitkarpe/curl-demo:latest` | cURL container for API testing |

### Enterprise Images (Podman/Buildah Workflow)
| Folder | Docker Hub | GHCR | Quay.io | Description |
|--------|------------|------|---------|-------------|
| `alpine` | `amitkarpe/alpine-enterprise:latest` | `ghcr.io/mytestlab123/alpine-enterprise:latest` | `quay.io/amitkarpe/alpine-enterprise:latest` | Enterprise Alpine Linux |
| `curl` | `amitkarpe/curl-enterprise:latest` | `ghcr.io/mytestlab123/curl-enterprise:latest` | `quay.io/amitkarpe/curl-enterprise:latest` | Enterprise cURL container |

**Registry Access:**
- **Docker Hub**: Public access, no authentication required
- **GHCR**: Private repos, requires GitHub token authentication  
- **Quay.io**: Public access after manual repository creation

## Quick Start Testing

### Multi-Registry Pull Testing

Use our comprehensive testing script:
```bash
# Test all images across all registries
./scripts/test-registry-pulls.sh --all

# Test specific image
./scripts/test-registry-pulls.sh alpine

# Test specific registry only
./scripts/test-registry-pulls.sh --all --registry dockerhub

# Test with Skopeo inspection
./scripts/test-registry-pulls.sh curl --inspect
```

### Manual Pull and Test Examples

#### Docker Hub (Public - No Auth Required)
```bash
# Pull standard images
docker pull amitkarpe/alpine-demo:latest
docker pull amitkarpe/curl-demo:latest

# Pull enterprise images  
docker pull amitkarpe/alpine-enterprise:latest
docker pull amitkarpe/curl-enterprise:latest

# Test images
docker run --rm amitkarpe/alpine-demo:latest echo "Docker Hub test"
podman run --rm amitkarpe/curl-enterprise:latest echo "Docker Hub test"
```

#### GHCR (Private - Auth Required)
```bash
# Authenticate first
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Pull images
docker pull ghcr.io/mytestlab123/alpine-demo:latest
docker pull ghcr.io/mytestlab123/curl-enterprise:latest

# Test images
docker run --rm ghcr.io/mytestlab123/alpine-demo:latest echo "GHCR test"
podman run --rm ghcr.io/mytestlab123/curl-enterprise:latest echo "GHCR test"
```

#### Quay.io (Public - Manual Repo Creation)
```bash
# Pull images (no auth needed for public repos)
docker pull quay.io/amitkarpe/alpine-demo:latest
docker pull quay.io/amitkarpe/curl-enterprise:latest

# Test images
docker run --rm quay.io/amitkarpe/alpine-demo:latest echo "Quay.io test"
podman run --rm quay.io/amitkarpe/curl-enterprise:latest echo "Quay.io test"
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

### Multi-Registry Testing Script
```bash
# Test all registries and images
./scripts/test-registry-pulls.sh --all

# Test specific scenarios
./scripts/test-registry-pulls.sh alpine --registry dockerhub
./scripts/test-registry-pulls.sh --all --suffix enterprise
./scripts/test-registry-pulls.sh curl --tools docker --inspect
```

### Quick Test All Images (Legacy)
```bash
#!/bin/bash
# test-all-images.sh - Updated for multi-registry

REGISTRIES=(
    "amitkarpe"
    "ghcr.io/mytestlab123" 
    "quay.io/amitkarpe"
)
IMAGES=("alpine-demo" "curl-demo" "alpine-enterprise" "curl-enterprise")

for registry in "${REGISTRIES[@]}"; do
    echo "Testing registry: $registry"
    for image in "${IMAGES[@]}"; do
        echo "Testing ${registry}/${image}:latest..."
        
        if docker run --rm "${registry}/${image}:latest" echo "✅ ${image} works" 2>/dev/null; then
            echo "✅ ${registry}/${image} test passed"
        else
            echo "❌ ${registry}/${image} test failed"
        fi
        echo "---"
    done
    echo ""
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

## Registry Access Troubleshooting

### Docker Hub Issues
```bash
# Rate limit errors
docker login docker.io  # Increases rate limits

# Test connectivity
curl -s https://index.docker.io/v1/ | head
```

### GHCR Issues  
```bash
# Authentication errors
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Test token permissions
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

### Quay.io Issues
```bash
# Repository not found errors
# - Verify repository was manually created by admin
# - Check repository visibility is public
# - Confirm robot account has access

# Test connectivity
curl -s https://quay.io/api/v1/discovery | head
```

## Reporting Issues

If you find issues during testing:

1. **Gather Information:**
   ```bash
   # Container tool versions
   docker version
   podman version
   
   # Registry login status
   docker info | grep -A5 "Registry:"
   
   # Test specific registry
   ./scripts/test-registry-pulls.sh FOLDER --registry REGISTRY_NAME
   ```

2. **Create Minimal Reproduction:**
   ```bash
   # Example reproduction steps
   docker pull amitkarpe/problematic-image:latest
   docker run --rm amitkarpe/problematic-image:latest command-that-fails
   ```

3. **Submit Issue:** Include:
   - Container tool version (Docker/Podman)
   - Registry being tested (Docker Hub/GHCR/Quay.io)
   - Authentication status
   - Complete error messages
   - Reproduction steps

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

## Additional Resources

- [Registry Access Guide](registry-access-guide.md) - Comprehensive registry access documentation
- [Enterprise Container Tools](enterprise-container-tools.md) - Podman/Buildah/Skopeo guide
- [Quay.io Integration Guide](quay-integration-guide.md) - Quay.io setup and testing

Happy testing! 🐳✨