# Enterprise Container Tools Guide

## 🏢 Overview

This project supports **enterprise-grade container tools** for enhanced security and compliance:

- **Buildah**: Rootless container image building
- **Podman**: Daemonless container runtime  
- **Skopeo**: Container image inspection and copying

## 🚀 Quick Start

### GitHub Actions (Automated)

The enterprise workflow automatically triggers on pushes to `main`:

```yaml
# .github/workflows/enterprise-podman-build.yml
- uses: redhat-actions/buildah-build@v2
- uses: redhat-actions/podman-login@v1
```

**Built images get `-enterprise` suffix:**
- `amitkarpe/alpine-enterprise:latest`
- `amitkarpe/curl-enterprise:latest`

### Local Development

Install enterprise tools:

```bash
# Ubuntu/Debian
sudo apt-get install podman buildah skopeo

# RHEL/Fedora
sudo dnf install podman buildah skopeo

# macOS (via Homebrew)
brew install podman buildah skopeo
```

## 🔧 Enterprise vs Standard Workflows

| Feature | Standard (Docker) | Enterprise (Podman/Buildah) |
|---------|------------------|---------------------------|
| **Runtime** | Docker daemon | Podman (daemonless) |
| **Builder** | Docker build | Buildah (rootless) |
| **Security** | Requires daemon | Rootless by default |
| **Compliance** | Standard | Enhanced enterprise |
| **Performance** | Good | Optimized for CI/CD |
| **Image suffix** | `-demo` | `-enterprise` |

## 📋 Enterprise Build Process

### 1. Rootless Building with Buildah

```bash
# Local development example
cd alpine/
buildah build-using-dockerfile -t alpine-enterprise .

# Multi-architecture (advanced)
buildah build-using-dockerfile \
  --arch amd64,arm64 \
  -t alpine-enterprise .
```

### 2. Daemonless Push with Podman

```bash
# Login to registries
podman login docker.io
podman login ghcr.io  
podman login quay.io

# Push to multiple registries
podman push alpine-enterprise:latest docker.io/amitkarpe/alpine-enterprise:latest
podman push alpine-enterprise:latest ghcr.io/mytestlab123/alpine-enterprise:latest
```

### 3. Security Inspection with Skopeo

```bash
# Inspect image metadata
skopeo inspect containers-storage:alpine-enterprise:latest

# Copy between registries (without local storage)
skopeo copy \
  docker://docker.io/amitkarpe/alpine-enterprise:latest \
  docker://quay.io/amitkarpe/alpine-enterprise:latest
```

## 🛡️ Security Advantages

### Rootless Containers
- **No root privileges required** for building images
- **Reduced attack surface** compared to Docker daemon
- **Enhanced isolation** between build processes

### Daemonless Architecture  
- **No background daemon** consuming resources
- **Direct container execution** without intermediary
- **Improved CI/CD performance** and reliability

### Container Security Scanning
```bash
# Advanced security inspection
skopeo inspect --config docker://amitkarpe/alpine-enterprise:latest

# Vulnerability scanning (with additional tools)
podman run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image amitkarpe/alpine-enterprise:latest
```

## 📦 Multi-Registry Enterprise Deployment

Both workflows deploy to the same registries:

### Docker Hub
- **Standard**: `amitkarpe/{folder}-demo:latest`
- **Enterprise**: `amitkarpe/{folder}-enterprise:latest`

### GitHub Container Registry (GHCR)
- **Standard**: `ghcr.io/mytestlab123/{folder}-demo:latest`  
- **Enterprise**: `ghcr.io/mytestlab123/{folder}-enterprise:latest`

### Quay.io (Optional)
- **Standard**: `quay.io/{username}/{folder}-demo:latest`
- **Enterprise**: `quay.io/{username}/{folder}-enterprise:latest`

## 🔄 Development Workflows

### Testing Enterprise Images Locally

```bash
# Pull and test enterprise images
podman pull amitkarpe/alpine-enterprise:latest
podman run --rm amitkarpe/alpine-enterprise:latest echo "Enterprise test"

# Compare with standard images
podman pull amitkarpe/alpine-demo:latest
podman run --rm amitkarpe/alpine-demo:latest echo "Standard test"
```

### Building Custom Enterprise Images

```bash
# Create new folder
mkdir my-enterprise-app
cd my-enterprise-app

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM registry.access.redhat.com/ubi8/ubi:latest

RUN dnf update -y && dnf install -y \
    your-enterprise-package \
    && dnf clean all

WORKDIR /app
COPY . /app

USER 1001
CMD ["your-enterprise-command"]
EOF

# Build with Buildah (rootless)
buildah build-using-dockerfile -t my-enterprise-app .

# Test locally with Podman (daemonless)
podman run --rm my-enterprise-app
```

## 🔍 Compliance and Auditing

### Image Provenance
Enterprise builds include enhanced metadata:

```bash
# Check build provenance
skopeo inspect docker://amitkarpe/alpine-enterprise:latest | jq '.Labels'

# Verify build tools
podman inspect amitkarpe/alpine-enterprise:latest | jq '.[0].Config.Labels'
```

### Compliance Reports
```bash
# Generate compliance report
echo "=== Enterprise Container Compliance Report ===" > compliance-report.txt
echo "Build Tool: Buildah (rootless)" >> compliance-report.txt
echo "Runtime: Podman (daemonless)" >> compliance-report.txt
echo "Security: Enhanced isolation" >> compliance-report.txt
skopeo inspect containers-storage:my-app:latest | jq '.Architecture,.Os' >> compliance-report.txt
```

## 🚀 CI/CD Integration

### GitHub Actions Enterprise Workflow

The enterprise workflow provides:
- ✅ **Parallel builds** alongside standard workflow
- ✅ **Same multi-registry support** (Docker Hub, GHCR, Quay.io)  
- ✅ **Enhanced security scanning** with Skopeo
- ✅ **Rootless/daemonless builds** for compliance
- ✅ **Enterprise image naming** (`-enterprise` suffix)

### Workflow Triggers
- **Push to main**: Builds and deploys enterprise images
- **Pull requests**: Builds and tests (no deployment)
- **Manual trigger**: Via GitHub Actions UI

## 📊 Performance Comparison

| Metric | Docker Workflow | Podman/Buildah Workflow |
|--------|----------------|------------------------|
| **Build time** | ~30-45s | ~25-40s |
| **Security** | Standard | Enhanced (rootless) |
| **Resource usage** | Higher (daemon) | Lower (daemonless) |
| **Compliance** | Basic | Enterprise-grade |

## 🔧 Troubleshooting

### Common Issues

**Buildah build fails:**
```bash
# Check Buildah version
buildah version

# Use specific Buildah version in CI
uses: redhat-actions/buildah-build@v2
```

**Podman registry login issues:**
```bash
# Clear podman auth
podman logout --all

# Re-login with debug
podman login --verbose docker.io
```

**Skopeo inspection fails:**
```bash
# Check image exists locally
podman images

# Use remote inspection
skopeo inspect docker://amitkarpe/alpine-enterprise:latest
```

## 📚 Additional Resources

- [Red Hat Buildah Documentation](https://buildah.io/)
- [Podman Official Guide](https://podman.io/)
- [Skopeo Container Tool](https://github.com/containers/skopeo)
- [Red Hat GitHub Actions](https://github.com/redhat-actions)

## 🎯 Next Steps

1. **Enable enterprise workflow** by merging the PR
2. **Test locally** with Podman/Buildah/Skopeo
3. **Configure additional registries** as needed
4. **Set up vulnerability scanning** for compliance
5. **Customize enterprise image naming** if required

---

🔒 **Enterprise-ready container builds with enhanced security and compliance!**