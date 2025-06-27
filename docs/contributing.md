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
```bash
# Build the image with Podman
podman build -t test-image .

# Alternative: Build with Buildah
buildah build-using-dockerfile -t test-image .

# Run the image
podman run --rm test-image

# Test with different configurations
podman run --rm -p 8080:80 test-image
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

Your container image will be automatically named as:
- **Folder name:** `my-awesome-app`
- **Registry image:** `amitkarpe/my-awesome-app-demo:latest`
- **Pull command:** `podman pull amitkarpe/my-awesome-app-demo:latest`

## What Happens Next

1. **Automated Testing:** GitHub Actions will build your image
2. **Review Process:** Maintainers will review your PR
3. **Merge & Deploy:** Once approved, your image will be built with Buildah and pushed to Docker Hub
4. **Public Access:** Anyone can use: `podman pull amitkarpe/my-awesome-app-demo`

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

## Need Help?

- Check existing folders for examples
- Review the [Testing Guide](testing.md)
- Open an issue if you have questions
- Join our community discussions

Happy contributing! 🚀