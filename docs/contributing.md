# Contributing Guide

## How to Add a New Docker Image

### Step 1: Create Your Folder
Create a new folder with a descriptive name:
```bash
mkdir my-awesome-app
cd my-awesome-app
```

### Step 2: Add Your Dockerfile
Create a `Dockerfile` in your folder:
```dockerfile
FROM ubuntu:22.04

# Your custom setup here
RUN apt-get update && apt-get install -y \
    your-package \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

CMD ["your-command"]
```

### Step 3: Add Supporting Files
Include any files your Docker image needs:
- Configuration files
- Scripts
- Static assets
- README files

### Step 4: Test Locally
Before submitting, test your container image:

#### Option A: Enterprise Tools (Recommended)
```bash
# Use the enterprise build script
./scripts/enterprise-build.sh your-folder-name --test

# Manual build with Buildah (rootless)
buildah build-using-dockerfile -t test-image .

# Run with Podman (daemonless)
podman run --rm test-image

# Security inspection with Skopeo
skopeo inspect containers-storage:test-image
```

#### Option B: Standard Tools
```bash
# Build the image with Docker
docker build -t test-image .

# Run the image
docker run --rm test-image

# Test with different configurations
docker run --rm -p 8080:80 test-image
```

### Step 5: Create a Pull Request

1. **Fork the repository** (if you haven't already)

2. **Create a new branch:**
   ```bash
   git checkout -b feature/add-my-awesome-app
   ```

3. **Add your changes:**
   ```bash
   git add .
   git commit -m "Add my-awesome-app Docker image"
   ```

4. **Push to your fork:**
   ```bash
   git push origin feature/add-my-awesome-app
   ```

5. **Create Pull Request:**
   - Go to the repository on GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill out the PR template

## Image Naming Convention

Your container images will be automatically named as:

### Standard Images (Docker workflow)
- **Folder name:** `my-awesome-app`
- **Registry image:** `amitkarpe/my-awesome-app-demo:latest`
- **Pull command:** `docker pull amitkarpe/my-awesome-app-demo:latest`

### Enterprise Images (Podman/Buildah workflow)
- **Folder name:** `my-awesome-app`  
- **Registry image:** `amitkarpe/my-awesome-app-enterprise:latest`
- **Pull command:** `podman pull amitkarpe/my-awesome-app-enterprise:latest`

Both image types are deployed to:
- Docker Hub: `amitkarpe/{name}-{suffix}:latest`
- GitHub Container Registry: `ghcr.io/mytestlab123/{name}-{suffix}:latest`
- Quay.io (optional): `quay.io/{username}/{name}-{suffix}:latest`

For Quay.io setup and testing, see the [Quay.io Integration Guide](quay-integration-guide.md).

## What Happens Next

1. **Automated Testing:** GitHub Actions will build your image with both workflows:
   - **Standard workflow**: Docker build → `amitkarpe/my-awesome-app-demo`
   - **Enterprise workflow**: Buildah build → `amitkarpe/my-awesome-app-enterprise`
2. **Review Process:** Maintainers will review your PR
3. **Merge & Deploy:** Once approved, images are pushed to multiple registries
4. **Public Access:** 
   - Standard: `docker pull amitkarpe/my-awesome-app-demo`
   - Enterprise: `podman pull amitkarpe/my-awesome-app-enterprise`

## Best Practices

### Container Build Tips
- Use multi-stage builds for smaller images
- Install only necessary packages  
- Use `.containerignore` or `.dockerignore` to exclude unnecessary files
- Pin version numbers for reproducible builds
- Test with both Podman and Buildah for compatibility

### Security Guidelines
- Don't include secrets or sensitive data
- Use non-root users when possible (Podman runs rootless by default)
- Keep base images updated
- Scan for vulnerabilities
- Leverage Podman's rootless security benefits

### Documentation
- Add a README.md in your folder explaining:
  - What your image does
  - How to use it
  - Configuration options
  - Examples

## Example Folder Structure
```
my-awesome-app/
├── Dockerfile
├── README.md
├── config/
│   └── app.conf
├── scripts/
│   └── entrypoint.sh
└── static/
    └── index.html
```

## Enterprise Container Tools

This project supports enterprise-grade container tools for enhanced security:

### Quick Start with Enterprise Tools
```bash
# Install tools (Ubuntu/Debian)
sudo apt-get install podman buildah skopeo

# Use the enterprise build script
./scripts/enterprise-build.sh --list
./scripts/enterprise-build.sh alpine --test --push

# Manual enterprise workflow
cd your-folder/
buildah build-using-dockerfile -t my-app-enterprise .
podman run --rm my-app-enterprise
skopeo inspect containers-storage:my-app-enterprise
```

### Enterprise vs Standard
- **Security**: Rootless builds (Buildah) vs daemon-based (Docker)
- **Performance**: Daemonless runtime (Podman) vs Docker daemon
- **Compliance**: Enhanced enterprise security posture
- **Images**: `-enterprise` suffix vs `-demo` suffix

For detailed enterprise container setup, see [Enterprise Container Tools Guide](enterprise-container-tools.md).

## Need Help?

- Check existing folders for examples
- Review the [Testing Guide](testing.md)
- Learn about [Enterprise Container Tools](enterprise-container-tools.md)
- Configure [Quay.io Integration](quay-integration-guide.md)
- Open an issue if you have questions
- Join our community discussions

Happy contributing! 🚀