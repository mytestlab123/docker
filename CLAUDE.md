# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Multi-registry Docker container pipeline with both standard Docker and enterprise Podman/Buildah workflows. Automatically builds and deploys container images to Docker Hub, GitHub Container Registry (GHCR), and Quay.io.

## Core Architecture

### Dual Workflow System
- **Standard Workflow** (`.github/workflows/multi-docker-build.yml`): Docker-based builds producing `{folder}-demo` images
- **Enterprise Workflow** (`.github/workflows/enterprise-podman-build.yml`): Podman/Buildah-based builds producing `{folder}-enterprise` images

### Auto-Discovery Pattern
Both workflows use dynamic folder detection:
```bash
find . -mindepth 2 -name "Dockerfile" -not -path "./.git/*" | xargs dirname | cut -c3- | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))'
```
Any folder containing a `Dockerfile` triggers automatic builds.

### Multi-Registry Deployment
Each image is deployed to three registries with specific patterns:
- **Docker Hub**: `amitkarpe/{folder}-{suffix}:latest` (Public)
- **GHCR**: `ghcr.io/mytestlab123/{folder}-{suffix}:latest` (Private)
- **Quay.io**: `quay.io/amitkarpe/{folder}-{suffix}:latest` (Public after manual setup)

## Common Commands

### Testing Multi-Registry Access
```bash
# Test all registries and images
./scripts/test-registry-pulls.sh --all

# Test specific image across all registries
./scripts/test-registry-pulls.sh alpine

# Test specific registry only
./scripts/test-registry-pulls.sh --all --registry dockerhub

# Test with Skopeo inspection
./scripts/test-registry-pulls.sh curl --inspect
```

### Enterprise Container Tools
```bash
# Build with enterprise tools locally
./scripts/enterprise-build.sh alpine --test

# Comprehensive Quay.io testing
./scripts/test-quay-integration.sh

# Quick Quay.io credentials verification
./scripts/quick-quay-test.sh
```

### Adding New Container Images
1. Create folder with `Dockerfile`
2. GitHub Actions automatically detects and builds
3. Images deploy to all three registries

## Registry-Specific Behavior

### Docker Hub
- Public access, no authentication needed
- Automatic repository creation
- Rate limits for anonymous pulls

### GitHub Container Registry (GHCR)
- **Private by default** - requires authentication for all access
- Authentication: `echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin`
- Unlimited pulls for authenticated users
- Automatic repository creation

### Quay.io
- **Manual repository creation required** by admin
- Robot account (`amitkarpe+mytestlab123`) can push but cannot create repos
- Public access after setup, no auth needed for pulls
- Hardcoded URLs (`quay.io/amitkarpe/`) work better than secret-based URLs

## Critical Implementation Details

### Workflow Secrets Required
- `DOCKER_USERNAME` / `DOCKER_PASSWORD`: Docker Hub authentication
- `GITHUB_TOKEN`: Automatic for GHCR (GitHub provides)
- `QUAY_USERNAME` / `QUAY_PASSWORD`: Quay.io robot account credentials

### Enterprise vs Standard Differences
- **Standard**: Uses Docker buildx, outputs to `{folder}-demo`
- **Enterprise**: Uses `redhat-actions/buildah-build@v2` and `redhat-actions/podman-login@v1`, outputs to `{folder}-enterprise`
- Both support same multi-registry deployment pattern
- Enterprise provides rootless builds and daemonless runtime

### Folder Structure Pattern
```
{folder}/
├── Dockerfile          # Required - triggers auto-build
├── README.md           # Optional - documentation
└── {additional-files}  # Optional - app-specific files
```

## Troubleshooting

### Common Issues
- **GHCR authentication failures**: Ensure GitHub token has `read:packages` scope
- **Quay.io repository not found**: Repository must be manually created by admin
- **Docker Hub rate limits**: Login to increase limits: `docker login docker.io`

### Workflow Debugging
- Check GitHub Actions logs for registry-specific failures
- Use `./scripts/test-registry-pulls.sh` to verify image accessibility
- Quay.io failures are expected if repositories haven't been manually created

## Documentation Structure

- `docs/registry-access-guide.md`: Comprehensive multi-registry access documentation
- `docs/enterprise-container-tools.md`: Podman/Buildah/Skopeo guide
- `docs/quay-integration-guide.md`: Quay.io setup and testing
- `docs/testing.md`: Image testing examples and scripts
- `docs/contributing.md`: New container image contribution guide