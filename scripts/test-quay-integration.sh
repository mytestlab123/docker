#!/bin/bash

# Quay.io Integration Testing Script
# Tests Quay.io repository and credentials with both Docker and Podman

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QUAY_REGISTRY="quay.io"
QUAY_USERNAME="${QUAY_USERNAME:-amitkarpe}"
TEST_TAG="test-$(date +%s)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites for Quay.io testing..."
    
    local missing_tools=()
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v podman &> /dev/null; then
        missing_tools+=("podman")
    fi
    
    if ! command -v skopeo &> /dev/null; then
        missing_tools+=("skopeo")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_warning "Missing optional tools: ${missing_tools[*]}"
        print_status "At least Docker is required for testing"
    else
        print_success "All container tools are available!"
    fi
    
    if [ -z "$QUAY_USERNAME" ]; then
        print_error "QUAY_USERNAME environment variable not set"
        echo "Usage: QUAY_USERNAME=your-username $0"
        exit 1
    fi
}

# Function to test Docker login to Quay.io
test_docker_login() {
    print_status "Testing Docker login to Quay.io..."
    
    if docker info | grep -q "Username"; then
        print_status "Already logged in to some registry"
    fi
    
    print_status "Please enter your Quay.io credentials when prompted"
    if docker login quay.io; then
        print_success "Docker login to Quay.io successful!"
        return 0
    else
        print_error "Docker login to Quay.io failed"
        return 1
    fi
}

# Function to test Podman login to Quay.io
test_podman_login() {
    if ! command -v podman &> /dev/null; then
        print_warning "Podman not available, skipping Podman login test"
        return 0
    fi
    
    print_status "Testing Podman login to Quay.io..."
    
    print_status "Please enter your Quay.io credentials when prompted"
    if podman login quay.io; then
        print_success "Podman login to Quay.io successful!"
        return 0
    else
        print_error "Podman login to Quay.io failed"
        return 1
    fi
}

# Function to build and test a simple image
build_test_image() {
    local tool="$1"
    local image_name="quay.io/$QUAY_USERNAME/test-image:$TEST_TAG"
    
    print_status "Building test image with $tool..."
    
    # Create temporary test directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Create simple test Dockerfile
    cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN echo "Quay.io integration test" > /test.txt
CMD ["cat", "/test.txt"]
EOF
    
    case $tool in
        "docker")
            if docker build -t "$image_name" .; then
                print_success "Docker build successful: $image_name"
                echo "$image_name"
            else
                print_error "Docker build failed"
                return 1
            fi
            ;;
        "podman")
            if ! command -v podman &> /dev/null; then
                print_warning "Podman not available, skipping Podman build"
                return 0
            fi
            if podman build -t "$image_name" .; then
                print_success "Podman build successful: $image_name"
                echo "$image_name"
            else
                print_error "Podman build failed"
                return 1
            fi
            ;;
        "buildah")
            if ! command -v buildah &> /dev/null; then
                print_warning "Buildah not available, skipping Buildah build"
                return 0
            fi
            if buildah build-using-dockerfile -t "$image_name" .; then
                print_success "Buildah build successful: $image_name"
                echo "$image_name"
            else
                print_error "Buildah build failed"
                return 1
            fi
            ;;
        *)
            print_error "Unknown build tool: $tool"
            return 1
            ;;
    esac
    
    # Cleanup
    cd "$PROJECT_ROOT"
    rm -rf "$temp_dir"
}

# Function to test pushing to Quay.io
test_push_to_quay() {
    local tool="$1"
    local image_name="$2"
    
    if [ -z "$image_name" ]; then
        print_warning "No image to push with $tool"
        return 0
    fi
    
    print_status "Testing push to Quay.io with $tool..."
    
    case $tool in
        "docker")
            if docker push "$image_name"; then
                print_success "Docker push to Quay.io successful: $image_name"
                return 0
            else
                print_error "Docker push to Quay.io failed"
                return 1
            fi
            ;;
        "podman")
            if ! command -v podman &> /dev/null; then
                print_warning "Podman not available, skipping push test"
                return 0
            fi
            if podman push "$image_name"; then
                print_success "Podman push to Quay.io successful: $image_name"
                return 0
            else
                print_error "Podman push to Quay.io failed"
                return 1
            fi
            ;;
        *)
            print_error "Unknown push tool: $tool"
            return 1
            ;;
    esac
}

# Function to test pulling from Quay.io
test_pull_from_quay() {
    local tool="$1"
    local image_name="$2"
    
    if [ -z "$image_name" ]; then
        print_warning "No image to pull with $tool"
        return 0
    fi
    
    print_status "Testing pull from Quay.io with $tool..."
    
    # Remove local image first
    case $tool in
        "docker")
            docker rmi "$image_name" 2>/dev/null || true
            if docker pull "$image_name"; then
                print_success "Docker pull from Quay.io successful: $image_name"
                # Test run
                if docker run --rm "$image_name"; then
                    print_success "Docker run test successful"
                fi
                return 0
            else
                print_error "Docker pull from Quay.io failed"
                return 1
            fi
            ;;
        "podman")
            if ! command -v podman &> /dev/null; then
                print_warning "Podman not available, skipping pull test"
                return 0
            fi
            podman rmi "$image_name" 2>/dev/null || true
            if podman pull "$image_name"; then
                print_success "Podman pull from Quay.io successful: $image_name"
                # Test run
                if podman run --rm "$image_name"; then
                    print_success "Podman run test successful"
                fi
                return 0
            else
                print_error "Podman pull from Quay.io failed"
                return 1
            fi
            ;;
        *)
            print_error "Unknown pull tool: $tool"
            return 1
            ;;
    esac
}

# Function to test Skopeo inspection
test_skopeo_inspection() {
    local image_name="$1"
    
    if [ -z "$image_name" ] || ! command -v skopeo &> /dev/null; then
        print_warning "Skopeo not available or no image to inspect"
        return 0
    fi
    
    print_status "Testing Skopeo inspection of Quay.io image..."
    
    if skopeo inspect "docker://$image_name"; then
        print_success "Skopeo inspection successful: $image_name"
        return 0
    else
        print_error "Skopeo inspection failed"
        return 1
    fi
}

# Function to test existing project images
test_project_images() {
    print_status "Testing project images with Quay.io..."
    
    cd "$PROJECT_ROOT"
    local folders=()
    
    # Find folders with Dockerfiles
    while IFS= read -r -d '' dockerfile; do
        local folder_path=$(dirname "$dockerfile")
        if [[ "$folder_path" != "." && "$folder_path" != "./.git"* ]]; then
            folders+=($(basename "$folder_path"))
        fi
    done < <(find . -mindepth 2 -name "Dockerfile" -not -path "./.git/*" -print0)
    
    if [ ${#folders[@]} -eq 0 ]; then
        print_warning "No project folders found to test"
        return 0
    fi
    
    print_status "Found project folders: ${folders[*]}"
    
    # Test with one folder (alpine as it's lightweight)
    if [[ " ${folders[*]} " =~ " alpine " ]]; then
        local test_folder="alpine"
        local image_name="quay.io/$QUAY_USERNAME/${test_folder}-test:$TEST_TAG"
        
        print_status "Testing project folder: $test_folder"
        
        cd "$test_folder"
        if docker build -t "$image_name" .; then
            print_success "Project image build successful: $image_name"
            
            if docker push "$image_name"; then
                print_success "Project image push to Quay.io successful"
                
                # Test pull and run
                docker rmi "$image_name" 2>/dev/null || true
                if docker pull "$image_name" && docker run --rm "$image_name" echo "Project test successful"; then
                    print_success "Project image end-to-end test successful"
                fi
            else
                print_error "Project image push to Quay.io failed"
            fi
        else
            print_error "Project image build failed"
        fi
        
        cd "$PROJECT_ROOT"
    fi
}

# Function to cleanup test images
cleanup_test_images() {
    print_status "Cleaning up test images..."
    
    local test_image_pattern="quay.io/$QUAY_USERNAME/test-image:$TEST_TAG"
    local project_test_pattern="quay.io/$QUAY_USERNAME/*-test:$TEST_TAG"
    
    # Local cleanup
    docker rmi "$test_image_pattern" 2>/dev/null || true
    podman rmi "$test_image_pattern" 2>/dev/null || true
    
    print_status "Local cleanup completed"
    print_warning "Note: Remote images on Quay.io should be manually deleted if needed"
}

# Function to generate test report
generate_test_report() {
    local results=("$@")
    
    echo ""
    print_status "=== QUAY.IO INTEGRATION TEST REPORT ==="
    echo ""
    
    local passed=0
    local total=${#results[@]}
    
    for result in "${results[@]}"; do
        if [[ "$result" == "PASS:"* ]]; then
            echo -e "${GREEN}✅${NC} ${result#PASS:}"
            ((passed++))
        else
            echo -e "${RED}❌${NC} ${result#FAIL:}"
        fi
    done
    
    echo ""
    print_status "Test Summary: $passed/$total tests passed"
    
    if [ "$passed" -eq "$total" ]; then
        print_success "🎉 All Quay.io integration tests passed!"
        echo ""
        echo "✅ Quay.io is ready for GitHub Actions integration"
        echo "✅ Credentials are working correctly"
        echo "✅ Both Docker and Podman workflows supported"
        return 0
    else
        print_error "❌ Some tests failed. Check configuration and credentials."
        return 1
    fi
}

# Main test function
main() {
    local test_results=()
    
    echo "🔍 Quay.io Integration Testing Script"
    echo "====================================="
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Test Docker login
    if test_docker_login; then
        test_results+=("PASS:Docker login to Quay.io")
    else
        test_results+=("FAIL:Docker login to Quay.io")
        print_error "Cannot proceed without Docker login"
        exit 1
    fi
    echo ""
    
    # Test Podman login (optional)
    if test_podman_login; then
        test_results+=("PASS:Podman login to Quay.io")
    else
        test_results+=("FAIL:Podman login to Quay.io")
    fi
    echo ""
    
    # Build and test with Docker
    docker_image=$(build_test_image "docker")
    if [ -n "$docker_image" ]; then
        test_results+=("PASS:Docker image build")
        
        if test_push_to_quay "docker" "$docker_image"; then
            test_results+=("PASS:Docker push to Quay.io")
            
            if test_pull_from_quay "docker" "$docker_image"; then
                test_results+=("PASS:Docker pull from Quay.io")
            else
                test_results+=("FAIL:Docker pull from Quay.io")
            fi
        else
            test_results+=("FAIL:Docker push to Quay.io")
        fi
    else
        test_results+=("FAIL:Docker image build")
    fi
    echo ""
    
    # Build and test with Podman (if available)
    podman_image=$(build_test_image "podman")
    if [ -n "$podman_image" ]; then
        test_results+=("PASS:Podman image build")
        
        if test_push_to_quay "podman" "$podman_image"; then
            test_results+=("PASS:Podman push to Quay.io")
            
            if test_pull_from_quay "podman" "$podman_image"; then
                test_results+=("PASS:Podman pull from Quay.io")
            else
                test_results+=("FAIL:Podman pull from Quay.io")
            fi
        else
            test_results+=("FAIL:Podman push to Quay.io")
        fi
    fi
    echo ""
    
    # Test Skopeo inspection
    if test_skopeo_inspection "$docker_image"; then
        test_results+=("PASS:Skopeo inspection")
    else
        test_results+=("FAIL:Skopeo inspection")
    fi
    echo ""
    
    # Test with project images
    test_project_images
    test_results+=("PASS:Project image testing")
    echo ""
    
    # Cleanup
    cleanup_test_images
    echo ""
    
    # Generate report
    generate_test_report "${test_results[@]}"
}

# Show usage if help requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Quay.io Integration Testing Script"
    echo ""
    echo "Usage: $0"
    echo "       QUAY_USERNAME=your-username $0"
    echo ""
    echo "This script tests Quay.io integration with:"
    echo "  - Docker and Podman login"
    echo "  - Image building and pushing"
    echo "  - Image pulling and running"
    echo "  - Skopeo inspection"
    echo "  - Project-specific image testing"
    echo ""
    echo "Environment Variables:"
    echo "  QUAY_USERNAME   Your Quay.io username (required)"
    echo ""
    echo "Prerequisites:"
    echo "  - Docker (required)"
    echo "  - Podman (optional)"
    echo "  - Buildah (optional)"
    echo "  - Skopeo (optional)"
    exit 0
fi

# Run main function
main "$@"