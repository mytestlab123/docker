# Multi-Registry Access Guide

## 🎯 Overview

This project deploys container images to three registries with different access patterns and requirements.

## 📦 Registry Summary

| Registry | Access | Authentication | Repository Creation | Image Types |
|----------|--------|----------------|-------------------|-------------|
| **Docker Hub** | Public | None for pulls | Automatic | `amitkarpe/{folder}-{suffix}` |
| **GHCR** | Private | GitHub token required | Automatic | `ghcr.io/mytestlab123/{folder}-{suffix}` |
| **Quay.io** | Public | None for pulls | Manual admin required | `quay.io/amitkarpe/{folder}-{suffix}` |

## 🔧 Image Naming Convention

### Standard Images (Docker Workflow)
- **Docker Hub**: `amitkarpe/{folder}-demo:latest`
- **GHCR**: `ghcr.io/mytestlab123/{folder}-demo:latest`
- **Quay.io**: `quay.io/amitkarpe/{folder}-demo:latest`

### Enterprise Images (Podman/Buildah Workflow)
- **Docker Hub**: `amitkarpe/{folder}-enterprise:latest`
- **GHCR**: `ghcr.io/mytestlab123/{folder}-enterprise:latest`
- **Quay.io**: `quay.io/amitkarpe/{folder}-enterprise:latest`

## 📋 Available Images

Current project folders and their deployed images:

### Alpine Container
```bash
# Docker Hub (Public)
docker pull amitkarpe/alpine-demo:latest
docker pull amitkarpe/alpine-enterprise:latest
podman pull amitkarpe/alpine-demo:latest
podman pull amitkarpe/alpine-enterprise:latest

# GHCR (Private - Auth Required)  
docker pull ghcr.io/mytestlab123/alpine-demo:latest
docker pull ghcr.io/mytestlab123/alpine-enterprise:latest
podman pull ghcr.io/mytestlab123/alpine-demo:latest
podman pull ghcr.io/mytestlab123/alpine-enterprise:latest

# Quay.io (Public - Manual Repo Creation)
docker pull quay.io/amitkarpe/alpine-demo:latest
docker pull quay.io/amitkarpe/alpine-enterprise:latest
podman pull quay.io/amitkarpe/alpine-demo:latest
podman pull quay.io/amitkarpe/alpine-enterprise:latest
```

### Curl Container
```bash
# Docker Hub (Public)
docker pull amitkarpe/curl-demo:latest
docker pull amitkarpe/curl-enterprise:latest

# GHCR (Private - Auth Required)
docker pull ghcr.io/mytestlab123/curl-demo:latest
docker pull ghcr.io/mytestlab123/curl-enterprise:latest

# Quay.io (Public - Manual Repo Creation)
docker pull quay.io/amitkarpe/curl-demo:latest
docker pull quay.io/amitkarpe/curl-enterprise:latest
```

## 🔐 Registry-Specific Access

### Docker Hub (Public Access)

**Characteristics:**
- ✅ Public repositories
- ✅ No authentication required for pulls
- ✅ Automatic repository creation
- ⚠️ Rate limits for anonymous pulls

**Usage:**
```bash
# Direct pull - no authentication needed
docker pull amitkarpe/alpine-demo:latest
podman pull amitkarpe/curl-enterprise:latest

# Run images directly
docker run --rm amitkarpe/alpine-demo:latest echo "Docker Hub test"
podman run --rm amitkarpe/curl-enterprise:latest echo "Docker Hub test"
```

**Rate Limit Mitigation:**
```bash
# Login to increase rate limits (optional)
docker login docker.io
podman login docker.io
```

### GitHub Container Registry (Private Access)

**Characteristics:**
- 🔒 Private repositories by default
- 🔑 GitHub token authentication required
- ✅ Automatic repository creation
- ✅ Unlimited pulls for authenticated users
- 🏢 Integrated with GitHub permissions

**Authentication Setup:**
```bash
# Create GitHub Personal Access Token with read:packages scope
# Via GitHub Settings > Developer settings > Personal access tokens

# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
echo $GITHUB_TOKEN | podman login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Alternative: Use GitHub CLI token
gh auth token | docker login ghcr.io -u $(gh api user --jq .login) --password-stdin
```

**Usage After Authentication:**
```bash
# Pull private images
docker pull ghcr.io/mytestlab123/alpine-demo:latest
podman pull ghcr.io/mytestlab123/curl-enterprise:latest

# Run authenticated images
docker run --rm ghcr.io/mytestlab123/alpine-demo:latest echo "GHCR test"
podman run --rm ghcr.io/mytestlab123/curl-enterprise:latest echo "GHCR test"
```

**Making GHCR Repositories Public:**
1. Go to GitHub package settings
2. Navigate to package visibility settings
3. Change from private to public
4. Confirm the change

### Quay.io (Manual Repository Creation)

**Characteristics:**
- 🏗️ Manual repository creation required
- 🤖 Robot account limitations (can push, cannot create repos)
- ✅ Public repositories after creation
- ✅ No authentication required for pulls
- 🔧 Admin access needed for new repositories

**Repository Creation Process:**
1. **Admin Login**: Login to Quay.io as admin user
2. **Create Repository**: Manually create `{folder}-demo` and `{folder}-enterprise` repos
3. **Set Permissions**: Grant robot account (`amitkarpe+mytestlab123`) write access
4. **Make Public**: Set repository visibility to public

**Usage After Repository Creation:**
```bash
# Pull public images (no auth needed)
docker pull quay.io/amitkarpe/alpine-demo:latest
podman pull quay.io/amitkarpe/curl-enterprise:latest

# Run images
docker run --rm quay.io/amitkarpe/alpine-demo:latest echo "Quay.io test"
podman run --rm quay.io/amitkarpe/curl-enterprise:latest echo "Quay.io test"
```

**Robot Account Limitations:**
- ✅ Can push to existing repositories
- ❌ Cannot create new repositories
- ⚠️ Requires admin pre-creation of repos
- 🔧 Needs explicit permissions for each repository

## 🧪 Testing Image Availability

### Quick Manual Testing
```bash
# Test Docker Hub (should always work)
docker pull amitkarpe/alpine-demo:latest && echo "✅ Docker Hub working"

# Test GHCR (requires authentication)
docker pull ghcr.io/mytestlab123/alpine-demo:latest && echo "✅ GHCR working"

# Test Quay.io (requires manual repo creation)
docker pull quay.io/amitkarpe/alpine-demo:latest && echo "✅ Quay.io working"
```

### Automated Testing Script
```bash
# Test all registries and images
./scripts/test-registry-pulls.sh --all

# Test specific image
./scripts/test-registry-pulls.sh alpine

# Test specific registry
./scripts/test-registry-pulls.sh --all --registry dockerhub

# Test with inspection
./scripts/test-registry-pulls.sh curl --inspect
```

## 🔍 Troubleshooting

### Common Issues

#### Docker Hub Rate Limits
```bash
# Error: toomanyrequests: Too Many Requests
# Solution: Login to increase limits
docker login docker.io
```

#### GHCR Authentication Failures
```bash
# Error: unauthorized: authentication required
# Solutions:
# 1. Create GitHub Personal Access Token with read:packages scope
export GITHUB_TOKEN="your_token_here"
export GITHUB_USERNAME="your_username"

# 2. Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# 3. Verify token has correct permissions
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

#### Quay.io Repository Not Found
```bash
# Error: repository does not exist
# Solutions:
# 1. Verify repository was manually created by admin
# 2. Check repository name matches expected pattern
# 3. Ensure repository is public
# 4. Confirm robot account has access
```

### Debugging Commands

#### Check Authentication Status
```bash
# Docker login status
docker info | grep -A5 "Registry:"

# Podman login status  
podman info | grep -A5 "registries"

# List configured registries
docker system info --format "{{.IndexServerAddress}}"
```

#### Test Registry Connectivity
```bash
# Test Docker Hub
curl -s https://index.docker.io/v1/ | head

# Test GHCR
curl -s https://ghcr.io/v2/ | head

# Test Quay.io
curl -s https://quay.io/api/v1/discovery | head
```

#### Inspect Images Remotely
```bash
# Use Skopeo to inspect without pulling
skopeo inspect docker://amitkarpe/alpine-demo:latest
skopeo inspect docker://ghcr.io/mytestlab123/alpine-demo:latest
skopeo inspect docker://quay.io/amitkarpe/alpine-demo:latest
```

## 📊 Registry Comparison

### Performance Characteristics
| Registry | Pull Speed | Availability | Geographic CDN |
|----------|------------|--------------|----------------|
| Docker Hub | Fast | High | Global |
| GHCR | Very Fast | High | Global |
| Quay.io | Fast | High | Global |

### Use Case Recommendations
- **Docker Hub**: Public distribution, general availability
- **GHCR**: GitHub integration, unlimited authenticated pulls
- **Quay.io**: Enterprise environments, private registries

### Cost Considerations
- **Docker Hub**: Free tier with rate limits, paid for private repos
- **GHCR**: Free for public repos, included with GitHub plans
- **Quay.io**: Free tier available, paid for additional features

## 🚀 Best Practices

### Multi-Registry Strategy
```bash
# Use different registries for different purposes:

# Development: Use GHCR for unlimited pulls
docker pull ghcr.io/mytestlab123/alpine-demo:latest

# Production: Use Docker Hub for public availability  
docker pull amitkarpe/alpine-demo:latest

# Enterprise: Use Quay.io for enhanced security
docker pull quay.io/amitkarpe/alpine-enterprise:latest
```

### Fallback Strategy
```bash
#!/bin/bash
# Try multiple registries for resilience

IMAGES=(
    "ghcr.io/mytestlab123/alpine-demo:latest"
    "amitkarpe/alpine-demo:latest"
    "quay.io/amitkarpe/alpine-demo:latest"
)

for image in "${IMAGES[@]}"; do
    if docker pull "$image"; then
        echo "Successfully pulled: $image"
        break
    else
        echo "Failed to pull: $image"
    fi
done
```

### Registry Selection Guide
- **High availability needs**: Use Docker Hub + GHCR
- **Private repositories**: Use GHCR
- **Rate limit concerns**: Use GHCR (unlimited for authenticated)
- **Enterprise compliance**: Use Quay.io
- **GitHub integration**: Use GHCR

## 📚 Additional Resources

- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [GitHub Container Registry Guide](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Quay.io Documentation](https://docs.quay.io/)
- [Podman Registry Authentication](https://docs.podman.io/en/latest/markdown/podman-login.1.html)

---

🌐 **Multi-registry deployment for maximum availability and flexibility!**