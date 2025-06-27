# Maintenance Guide for Repository Owners

## Pull Request Review Process

### 1. Initial Review Checklist

When a new PR comes in, verify:

- [ ] **Folder Structure:** New folder contains a valid `Dockerfile`
- [ ] **Naming Convention:** Folder name is descriptive and appropriate
- [ ] **Security Scan:** No secrets, sensitive data, or malicious content
- [ ] **Best Practices:** Dockerfile follows security and efficiency guidelines
- [ ] **Documentation:** Includes basic README or comments

### 2. GitHub Actions Review

#### Monitor the Build Process
1. **Check Actions Tab:** Go to repository → Actions
2. **Review Build Logs:** Look for any failures or warnings
3. **Verify Matrix Builds:** Ensure all folders build successfully

#### Action Monitoring Commands
```bash
# View recent workflow runs
gh run list --limit 10

# Watch a specific run
gh run watch <run-id>

# View logs for failed runs
gh run view <run-id> --log
```

### 3. Pre-Merge Validation

Before approving a PR:

```bash
# Pull the PR branch
gh pr checkout <pr-number>

# Test build locally
cd <new-folder>
docker build -t test-image .

# Test the image
docker run --rm test-image

# Check image size
docker images test-image
```

### 4. Docker Hub Verification

After merging to main:

1. **Verify Push:** Check that images are pushed to Docker Hub
2. **Test Pull:** Pull and test the new image
3. **Update Documentation:** Ensure image is listed in project docs

```bash
# Verify image was pushed
docker pull amitkarpe/<folder-name>-demo:latest

# Test the pulled image
docker run --rm amitkarpe/<folder-name>-demo:latest
```

## Action Runner Management

### Monitoring GitHub Actions

#### Key Metrics to Watch
- **Build Success Rate:** Aim for >95%
- **Build Duration:** Monitor for increasing build times
- **Resource Usage:** Watch for memory/disk issues
- **Concurrent Builds:** Ensure matrix builds don't exceed limits

#### Common Issues & Solutions

**1. Build Timeouts**
```yaml
# Increase timeout in workflow
jobs:
  build:
    timeout-minutes: 30  # Default is 6 hours
```

**2. Docker Hub Rate Limits**
- Monitor Docker Hub usage
- Consider using GitHub Container Registry as alternative
- Implement build caching

**3. Secret Management**
```bash
# Verify secrets are set
gh secret list

# Update Docker credentials if needed
gh secret set DOCKER_USERNAME --body "amitkarpe"
gh secret set DOCKER_PASSWORD --body "your-token"
```

### Workflow Optimization

#### Enable Build Caching
The workflow already includes GitHub Actions cache:
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

#### Monitor Resource Usage
- Check for large images (>1GB)
- Review unnecessary dependencies
- Suggest multi-stage builds when appropriate

### Security Considerations

#### Regular Security Tasks
- [ ] **Monthly:** Review Docker base image updates
- [ ] **Quarterly:** Audit secrets and permissions
- [ ] **Per PR:** Scan for vulnerabilities and secrets

#### Security Tools Integration
Consider adding to workflow:
```yaml
- name: Run security scan
  uses: docker/scout-action@v1
  with:
    command: cves
    image: ${{ steps.image.outputs.name }}:latest
```

## Repository Administration

### Branch Protection Rules
Ensure main branch has:
- [ ] Require PR reviews (at least 1)
- [ ] Require status checks (GitHub Actions)
- [ ] Require branches to be up to date
- [ ] Restrict pushes to main

### Issue Management
- Label PRs appropriately (`docker`, `enhancement`, `bug`)
- Use milestones for release planning
- Close stale issues monthly

### Community Management
- Respond to issues within 48 hours
- Provide constructive feedback on PRs
- Maintain contributor documentation
- Recognize community contributions

## Troubleshooting Common Problems

### Build Failures
1. **Dockerfile Syntax:** Validate Dockerfile syntax
2. **Missing Files:** Check if all COPY/ADD files exist
3. **Network Issues:** Retry failed builds
4. **Base Image Issues:** Verify base image availability

### Docker Hub Issues
1. **Authentication:** Verify credentials in secrets
2. **Rate Limits:** Implement retry logic or caching
3. **Repository Permissions:** Ensure push permissions

### GitHub Actions Issues
1. **Quota Limits:** Monitor action minutes usage
2. **Runner Issues:** Check for runner availability
3. **Workflow Syntax:** Validate YAML syntax

## Performance Monitoring

### Metrics to Track
- Average build time per image
- Success/failure rates
- Docker Hub pull statistics
- Community engagement (stars, forks, issues)

### Optimization Opportunities
- Implement selective builds (only changed folders)
- Use BuildKit for faster builds
- Optimize Dockerfile layers
- Consider parallel builds for large repositories

## Communication

### PR Feedback Templates
Use consistent feedback templates:

**For Dockerfile Issues:**
```markdown
Thanks for your contribution! A few suggestions:

- Consider using multi-stage builds to reduce image size
- Pin package versions for reproducible builds
- Add a .dockerignore file to exclude unnecessary files

Please update and I'll review again.
```

**For Approval:**
```markdown
Great work! ✅ 

Your Docker image builds successfully and follows our best practices. 
Once merged, it will be available as `amitkarpe/<folder>-demo:latest`.

Thanks for contributing to the project!
```

## Escalation Process

If you encounter issues beyond normal maintenance:

1. **Technical Issues:** Create internal issue with `maintenance` label
2. **Security Concerns:** Follow security disclosure process
3. **Community Issues:** Escalate to project leads
4. **Infrastructure Problems:** Contact GitHub support

Remember: The goal is to maintain a healthy, secure, and efficient Docker image repository that serves the community well! 🛠️