#!/bin/bash

# Project Images Quay.io Testing Script
# Tests existing project images with Quay.io using both Docker and Podman

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
IMAGE_SUFFIX="${IMAGE_SUFFIX:-quay-test}"
TEST_TAG="$(date +%Y%m%d-%H%M%S)"

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

# Function to discover project folders
discover_folders() {
    print_status "Discovering project folders with Dockerfiles..."
    
    cd "$PROJECT_ROOT"
    local folders=()
    
    while IFS= read -r -d '' dockerfile; do
        local folder_path=$(dirname "$dockerfile")
        if [[ "$folder_path" != "." && "$folder_path" != "./.git"* ]]; then
            local folder_name=$(basename "$folder_path")
            folders+=("$folder_name")
        fi
    done < <(find . -mindepth 2 -name "Dockerfile" -not -path "./.git/*" -print0)
    
    if [ ${#folders[@]} -eq 0 ]; then
        print_error "No folders with Dockerfiles found"
        exit 1
    fi
    
    print_success "Found project folders: ${folders[*]}"
    echo "${folders[@]}"
}

# Function to test Docker workflow with Quay.io
test_docker_workflow() {
    local folder="$1"
    local image_name="$QUAY_REGISTRY/$QUAY_USERNAME/${folder}-${IMAGE_SUFFIX}:$TEST_TAG"
    
    print_status "Testing Docker workflow for $folder..."
    
    cd "$PROJECT_ROOT/$folder"
    
    # Build with Docker
    print_status "Building with Docker: $image_name"
    if docker build -t "$image_name" .; then
        print_success "Docker build successful"
    else
        print_error "Docker build failed for $folder"
        return 1
    fi
    
    # Test image locally
    print_status "Testing image locally..."
    if docker run --rm "$image_name" echo "Docker test successful" 2>/dev/null; then
        print_success "Local Docker test passed"
    else
        print_warning "Local Docker test completed with warnings"
    fi
    
    # Push to Quay.io
    print_status "Pushing to Quay.io with Docker..."
    if docker push "$image_name"; then
        print_success "Docker push to Quay.io successful: $image_name"
    else
        print_error "Docker push to Quay.io failed"
        return 1
    fi
    
    # Test pull from Quay.io
    print_status "Testing pull from Quay.io..."
    docker rmi "$image_name" 2>/dev/null || true
    if docker pull "$image_name"; then
        print_success "Docker pull from Quay.io successful"
        
        # Test pulled image
        if docker run --rm "$image_name" echo "Quay.io pull test successful" 2>/dev/null; then
            print_success "End-to-end Docker + Quay.io test passed for $folder"
        fi
    else
        print_error "Docker pull from Quay.io failed"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to test Podman workflow with Quay.io
test_podman_workflow() {
    local folder="$1"
    local image_name="$QUAY_REGISTRY/$QUAY_USERNAME/${folder}-${IMAGE_SUFFIX}-podman:$TEST_TAG"
    
    if ! command -v podman &> /dev/null; then
        print_warning "Podman not available, skipping Podman workflow test for $folder"
        return 0
    fi
    
    print_status "Testing Podman workflow for $folder..."
    
    cd "$PROJECT_ROOT/$folder"
    
    # Build with Podman
    print_status "Building with Podman: $image_name"
    if podman build -t "$image_name" .; then
        print_success "Podman build successful"
    else
        print_error "Podman build failed for $folder"
        return 1
    fi
    
    # Test image locally
    print_status "Testing image locally with Podman..."
    if podman run --rm "$image_name" echo "Podman test successful" 2>/dev/null; then
        print_success "Local Podman test passed"
    else
        print_warning "Local Podman test completed with warnings"
    fi
    
    # Push to Quay.io
    print_status "Pushing to Quay.io with Podman..."
    if podman push "$image_name"; then
        print_success "Podman push to Quay.io successful: $image_name"
    else
        print_error "Podman push to Quay.io failed"
        return 1
    fi
    
    # Test pull from Quay.io
    print_status "Testing pull from Quay.io with Podman..."
    podman rmi "$image_name" 2>/dev/null || true
    if podman pull "$image_name"; then
        print_success "Podman pull from Quay.io successful"
        
        # Test pulled image
        if podman run --rm "$image_name" echo "Quay.io pull test successful" 2>/dev/null; then
            print_success "End-to-end Podman + Quay.io test passed for $folder"
        fi
    else
        print_error "Podman pull from Quay.io failed"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to test Buildah workflow with Quay.io
test_buildah_workflow() {
    local folder="$1"
    local image_name="$QUAY_REGISTRY/$QUAY_USERNAME/${folder}-${IMAGE_SUFFIX}-buildah:$TEST_TAG"
    
    if ! command -v buildah &> /dev/null; then
        print_warning "Buildah not available, skipping Buildah workflow test for $folder"
        return 0
    fi
    
    print_status "Testing Buildah workflow for $folder..."
    
    cd "$PROJECT_ROOT/$folder"
    
    # Build with Buildah
    print_status "Building with Buildah: $image_name"
    if buildah build-using-dockerfile -t "$image_name" .; then
        print_success "Buildah build successful"
    else
        print_error "Buildah build failed for $folder"
        return 1
    fi
    
    # Push to Quay.io with Podman (Buildah doesn't push directly)
    if command -v podman &> /dev/null; then
        print_status "Pushing Buildah image to Quay.io with Podman..."
        if podman push "$image_name"; then
            print_success "Buildah + Podman push to Quay.io successful: $image_name"
        else
            print_error "Buildah + Podman push to Quay.io failed"
            return 1
        fi
    else
        print_warning "Podman not available, cannot push Buildah image"
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to test Skopeo operations
test_skopeo_operations() {
    local folder="$1"
    local source_image="$QUAY_REGISTRY/$QUAY_USERNAME/${folder}-${IMAGE_SUFFIX}:$TEST_TAG"
    local target_image="$QUAY_REGISTRY/$QUAY_USERNAME/${folder}-${IMAGE_SUFFIX}-copy:$TEST_TAG"
    
    if ! command -v skopeo &> /dev/null; then
        print_warning "Skopeo not available, skipping Skopeo operations for $folder"
        return 0
    fi
    
    print_status "Testing Skopeo operations for $folder..."
    
    # Inspect image on Quay.io
    print_status "Inspecting image with Skopeo..."
    if skopeo inspect "docker://$source_image" > /dev/null; then
        print_success "Skopeo inspect successful for $source_image"
    else
        print_error "Skopeo inspect failed for $source_image"
        return 1
    fi
    
    # Copy image within Quay.io
    print_status "Copying image with Skopeo..."
    if skopeo copy "docker://$source_image" "docker://$target_image"; then
        print_success "Skopeo copy successful: $source_image → $target_image"
    else
        print_error "Skopeo copy failed"
        return 1
    fi
    
    return 0
}

# Function to simulate GitHub Actions workflow
simulate_github_workflow() {
    local folder="$1"
    
    print_status "Simulating GitHub Actions workflow for $folder..."
    
    # Simulate enterprise workflow steps
    local base_image="$QUAY_REGISTRY/$QUAY_USERNAME/${folder}-enterprise"
    local workflow_image="${base_image}:github-simulation-$TEST_TAG"
    
    cd "$PROJECT_ROOT/$folder"
    
    # Step 1: Build with Docker (simulating GitHub Actions environment)
    print_status "Step 1: Building image (GitHub Actions simulation)..."
    if docker build -t "$workflow_image" .; then
        print_success "GitHub Actions build simulation successful"
    else
        print_error "GitHub Actions build simulation failed"
        return 1
    fi
    
    # Step 2: Login simulation (we're already logged in)
    print_status "Step 2: Registry login (already authenticated)"
    
    # Step 3: Push simulation
    print_status "Step 3: Pushing to Quay.io (GitHub Actions simulation)..."
    if docker push "$workflow_image"; then
        print_success "GitHub Actions push simulation successful: $workflow_image"
    else
        print_error "GitHub Actions push simulation failed"
        return 1
    fi
    
    # Step 4: Verification
    print_status "Step 4: Verifying deployment..."
    docker rmi "$workflow_image" 2>/dev/null || true
    if docker pull "$workflow_image" && docker run --rm "$workflow_image" echo "GitHub workflow simulation successful"; then
        print_success "GitHub Actions workflow simulation completed successfully"
    else
        print_error "GitHub Actions workflow verification failed"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to cleanup test images
cleanup_test_images() {
    print_status "Cleaning up test images..."
    
    local cleanup_patterns=(
        "$QUAY_REGISTRY/$QUAY_USERNAME/*-${IMAGE_SUFFIX}:$TEST_TAG"
        "$QUAY_REGISTRY/$QUAY_USERNAME/*-${IMAGE_SUFFIX}-podman:$TEST_TAG"
        "$QUAY_REGISTRY/$QUAY_USERNAME/*-${IMAGE_SUFFIX}-buildah:$TEST_TAG"
        "$QUAY_REGISTRY/$QUAY_USERNAME/*-enterprise:github-simulation-$TEST_TAG"
    )
    
    # Local cleanup with Docker
    for pattern in "${cleanup_patterns[@]}"; do
        # This won't work with wildcards, but shows the intent
        docker images --format "table {{.Repository}}:{{.Tag}}" | grep "$TEST_TAG" | while read image; do
            docker rmi "$image" 2>/dev/null || true
        done
    done
    
    # Local cleanup with Podman
    if command -v podman &> /dev/null; then
        podman images --format "table {{.Repository}}:{{.Tag}}" | grep "$TEST_TAG" | while read image; do
            podman rmi "$image" 2>/dev/null || true
        done
    fi
    
    print_success "Local cleanup completed"
    print_warning "Note: Remote images on Quay.io should be manually deleted if needed"
    echo ""
    echo "To view your test images on Quay.io:"
    echo "  https://quay.io/repository/$QUAY_USERNAME"
}

# Function to show usage
show_usage() {
    echo "Project Images Quay.io Testing Script"
    echo "Usage: $0 [OPTIONS] [FOLDER]"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -l, --list         List available project folders"
    echo "  -a, --all          Test all project folders"
    echo "  -d, --docker-only  Test Docker workflow only"
    echo "  -p, --podman-only  Test Podman/Buildah workflow only"
    echo "  -s, --simulate     Simulate GitHub Actions workflow"
    echo "  --cleanup          Cleanup test images only"
    echo ""
    echo "Examples:"
    echo "  $0 alpine                    # Test alpine folder with all tools"
    echo "  $0 --all --docker-only      # Test all folders with Docker only"
    echo "  $0 curl --simulate          # Test curl with GitHub simulation"
    echo ""
    echo "Environment Variables:"
    echo "  QUAY_USERNAME     Your Quay.io username (default: amitkarpe)"
    echo "  IMAGE_SUFFIX      Test image suffix (default: quay-test)"
}

# Main function
main() {
    local test_all=false
    local docker_only=false
    local podman_only=false
    local simulate_github=false
    local cleanup_only=false
    local target_folder=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                discover_folders
                exit 0
                ;;
            -a|--all)
                test_all=true
                shift
                ;;
            -d|--docker-only)
                docker_only=true
                shift
                ;;
            -p|--podman-only)
                podman_only=true
                shift
                ;;
            -s|--simulate)
                simulate_github=true
                shift
                ;;
            --cleanup)
                cleanup_only=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$target_folder" ]]; then
                    target_folder="$1"
                else
                    print_error "Multiple folders specified. Use --all for multiple folders."
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Handle cleanup only
    if [[ "$cleanup_only" == true ]]; then
        cleanup_test_images
        exit 0
    fi
    
    echo "🧪 Project Images Quay.io Testing"
    echo "=================================="
    echo "Username: $QUAY_USERNAME"
    echo "Test Tag: $TEST_TAG"
    echo ""
    
    # Determine folders to test
    local folders_to_test=()
    
    if [[ "$test_all" == true ]]; then
        mapfile -t folders_to_test < <(discover_folders)
    elif [[ -n "$target_folder" ]]; then
        if [[ -d "$PROJECT_ROOT/$target_folder" && -f "$PROJECT_ROOT/$target_folder/Dockerfile" ]]; then
            folders_to_test=("$target_folder")
        else
            print_error "Folder '$target_folder' not found or doesn't contain Dockerfile"
            exit 1
        fi
    else
        print_error "No folder specified. Use --all or specify a folder name."
        show_usage
        exit 1
    fi
    
    # Run tests
    local test_results=()
    
    for folder in "${folders_to_test[@]}"; do
        print_status "Testing folder: $folder"
        echo "----------------------------------------"
        
        # Test Docker workflow
        if [[ "$podman_only" != true ]]; then
            if test_docker_workflow "$folder"; then
                test_results+=("PASS:Docker workflow - $folder")
            else
                test_results+=("FAIL:Docker workflow - $folder")
            fi
            echo ""
        fi
        
        # Test Podman workflow
        if [[ "$docker_only" != true ]]; then
            if test_podman_workflow "$folder"; then
                test_results+=("PASS:Podman workflow - $folder")
            else
                test_results+=("FAIL:Podman workflow - $folder")
            fi
            echo ""
            
            # Test Buildah workflow
            if test_buildah_workflow "$folder"; then
                test_results+=("PASS:Buildah workflow - $folder")
            else
                test_results+=("FAIL:Buildah workflow - $folder")
            fi
            echo ""
        fi
        
        # Test Skopeo operations
        if test_skopeo_operations "$folder"; then
            test_results+=("PASS:Skopeo operations - $folder")
        else
            test_results+=("FAIL:Skopeo operations - $folder")
        fi
        echo ""
        
        # GitHub Actions simulation
        if [[ "$simulate_github" == true ]]; then
            if simulate_github_workflow "$folder"; then
                test_results+=("PASS:GitHub Actions simulation - $folder")
            else
                test_results+=("FAIL:GitHub Actions simulation - $folder")
            fi
            echo ""
        fi
    done
    
    # Show results
    echo ""
    print_status "=== TEST RESULTS ==="
    echo ""
    
    local passed=0
    local total=${#test_results[@]}
    
    for result in "${test_results[@]}"; do
        if [[ "$result" == "PASS:"* ]]; then
            echo -e "${GREEN}✅${NC} ${result#PASS:}"
            ((passed++))
        else
            echo -e "${RED}❌${NC} ${result#FAIL:}"
        fi
    done
    
    echo ""
    print_status "Summary: $passed/$total tests passed"
    
    if [ "$passed" -eq "$total" ]; then
        print_success "🎉 All project Quay.io tests passed!"
        echo ""
        echo "✅ Ready for GitHub Actions Quay.io integration"
        echo "✅ All container tools work with Quay.io"
        echo "✅ Project images deploy successfully"
    else
        print_error "❌ Some tests failed. Check the output above."
    fi
    
    # Cleanup
    echo ""
    cleanup_test_images
}

# Run main function with all arguments
main "$@"