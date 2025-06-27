# Quay.io Integration Guide

## 🎯 Overview

This guide helps you test and configure Quay.io integration for both local development and GitHub Actions workflows.

## 🚀 Quick Testing

### Step 1: Test Your Credentials

Use our quick verification script:

```bash
# Quick credentials test
./scripts/quick-quay-test.sh

# If not logged in, login first:
docker login -u="your-username" quay.io
```

### Step 2: Comprehensive Testing

Test all project images with Quay.io:

```bash
# Test specific folder
QUAY_USERNAME=your-username ./scripts/test-project-quay.sh alpine

# Test all folders
QUAY_USERNAME=your-username ./scripts/test-project-quay.sh --all

# Test with Docker only
QUAY_USERNAME=your-username ./scripts/test-project-quay.sh --all --docker-only

# Simulate GitHub Actions workflow
QUAY_USERNAME=your-username ./scripts/test-project-quay.sh curl --simulate
```

### Step 3: Full Integration Testing

Complete Quay.io integration test:

```bash
# Comprehensive test with all tools
QUAY_USERNAME=your-username ./scripts/test-quay-integration.sh
```

## 🔧 Local Development Setup

### Prerequisites

Install container tools:

```bash
# Ubuntu/Debian
sudo apt-get install docker.io podman buildah skopeo

# RHEL/Fedora  
sudo dnf install docker podman buildah skopeo

# macOS
brew install docker podman buildah skopeo
```

### Manual Testing Workflow

```bash
# 1. Login to Quay.io
docker login -u="your-username" quay.io
podman login quay.io  # Optional: for Podman workflow

# 2. Build test image
cd alpine/  # or any project folder
docker build -t quay.io/your-username/alpine-test .

# 3. Push to Quay.io
docker push quay.io/your-username/alpine-test

# 4. Test pull and run
docker rmi quay.io/your-username/alpine-test
docker pull quay.io/your-username/alpine-test
docker run --rm quay.io/your-username/alpine-test echo "Success!"
```

## 🏗️ GitHub Actions Integration

### Current Status

Both workflows support Quay.io integration:

- **Standard workflow** (`multi-docker-build.yml`): `{folder}-demo` images
- **Enterprise workflow** (`enterprise-podman-build.yml`): `{folder}-enterprise` images

### GitHub Secrets Configuration

Set up these secrets in your repository:

```bash
# Via GitHub CLI
gh secret set QUAY_USERNAME --body "your-username"
gh secret set QUAY_PASSWORD --body "your-app-password"

# Via GitHub Web UI
# Settings > Secrets and variables > Actions > New repository secret
```

### Quay.io Username Format

For robot accounts or organization access:

```bash
# Personal account
QUAY_USERNAME=your-username

# Robot account  
QUAY_USERNAME=your-username+robot-name

# Organization
QUAY_USERNAME=organization+robot-name
```

### Testing GitHub Integration

1. **Local simulation**:
   ```bash
   ./scripts/test-project-quay.sh alpine --simulate
   ```

2. **Trigger actual workflow**:
   - Create a test PR or push to main
   - Check GitHub Actions logs for Quay.io push status

3. **Verify deployment**:
   ```bash
   # Check if images are available
   docker pull quay.io/your-username/alpine-demo:latest
   docker pull quay.io/your-username/alpine-enterprise:latest
   ```

## 🔍 Troubleshooting

### Common Issues

#### 1. Login Failures

```bash
# Check current login status
docker info | grep Username

# Re-login with explicit credentials
docker login -u="username" -p="password" quay.io

# Test authentication
docker pull quay.io/your-username/any-public-image
```

#### 2. Push Permission Errors

```bash
# Error: denied: requested access to the resource is denied
# Solutions:
# 1. Check repository exists and is public/private correctly
# 2. Verify username format (especially for robot accounts)
# 3. Confirm password/token is correct
# 4. Check repository permissions
```

#### 3. GitHub Actions Failures

```bash
# Check workflow logs for:
# - "QUAY_USERNAME available: true/false"
# - "QUAY_PASSWORD available: true/false"  
# - Actual error messages in push step

# Common fixes:
# 1. Verify secrets are set correctly
# 2. Check username format in secrets
# 3. Regenerate app password/token
# 4. Verify repository permissions
```

#### 4. Image Reference Errors

```bash
# Error: invalid reference format
# Check for:
# - Special characters in username
# - Correct repository naming
# - Proper tag format

# Valid formats:
quay.io/username/repository:tag
quay.io/username+robot/repository:tag
```

### Debug Commands

```bash
# Test Quay.io connectivity
curl -s https://quay.io/api/v1/repository/your-username/test-repo

# Inspect Quay.io image
skopeo inspect docker://quay.io/your-username/alpine-demo:latest

# Check local image tags
docker images | grep quay.io
podman images | grep quay.io

# Test registry authentication
docker run --rm curlimages/curl curl -u "username:password" \
  https://quay.io/api/v1/user/
```

## 📊 Testing Results Interpretation

### Successful Test Output

```
🎉 All Quay.io integration tests passed!

✅ Quay.io is ready for GitHub Actions integration
✅ Credentials are working correctly  
✅ Both Docker and Podman workflows supported
```

### Failed Test Indicators

```
❌ Docker login to Quay.io failed
❌ Docker push to Quay.io failed  
❌ Podman push to Quay.io failed
```

## 🚀 Production Deployment

### Multi-Registry Strategy

After successful testing, your images will be available on:

1. **Docker Hub**: `amitkarpe/{folder}-{suffix}:latest`
2. **GitHub Container Registry**: `ghcr.io/mytestlab123/{folder}-{suffix}:latest`  
3. **Quay.io**: `quay.io/your-username/{folder}-{suffix}:latest`

### Rate Limit Mitigation

```bash
# Use different registries for different purposes:
# - Docker Hub: Public distribution
# - GHCR: Unlimited GitHub integration
# - Quay.io: Enterprise/private distribution
```

### Image Naming Convention

- **Standard images**: `{folder}-demo` (e.g., `alpine-demo`)
- **Enterprise images**: `{folder}-enterprise` (e.g., `alpine-enterprise`)

## 📚 Additional Resources

- [Quay.io Documentation](https://docs.quay.io/)
- [Docker Login Documentation](https://docs.docker.com/engine/reference/commandline/login/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Podman Registry Authentication](https://docs.podman.io/en/latest/markdown/podman-login.1.html)

## 🎯 Next Steps

1. **Test credentials**: Run `./scripts/quick-quay-test.sh`
2. **Verify project images**: Run `./scripts/test-project-quay.sh --all`
3. **Configure GitHub secrets**: Set `QUAY_USERNAME` and `QUAY_PASSWORD`
4. **Test GitHub integration**: Create test PR or push to main
5. **Monitor deployments**: Check all three registries for images

---

🔒 **Secure, multi-registry container deployment with Quay.io integration!**