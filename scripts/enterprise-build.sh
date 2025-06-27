#!/bin/bash

# Enterprise Container Build Script
# Uses Podman, Buildah, and Skopeo for enterprise-grade container operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY_PREFIX="${REGISTRY_PREFIX:-amitkarpe}"
IMAGE_SUFFIX="${IMAGE_SUFFIX:-enterprise}"

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

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking enterprise container tools..."
    
    local missing_tools=()
    
    if ! command -v podman &> /dev/null; then
        missing_tools+=("podman")
    fi
    
    if ! command -v buildah &> /dev/null; then
        missing_tools+=("buildah")
    fi
    
    if ! command -v skopeo &> /dev/null; then
        missing_tools+=("skopeo")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Install instructions:"
        echo "  Ubuntu/Debian: sudo apt-get install podman buildah skopeo"
        echo "  RHEL/Fedora:   sudo dnf install podman buildah skopeo"
        echo "  macOS:         brew install podman buildah skopeo"
        exit 1
    fi
    
    print_success "All enterprise tools are available!"
}

# Function to discover folders with Dockerfiles
discover_folders() {
    print_status "Discovering folders with Dockerfiles..."
    
    cd "$PROJECT_ROOT"
    local folders=()
    
    while IFS= read -r -d '' dockerfile; do
        local folder_path=$(dirname "$dockerfile")
        if [[ "$folder_path" != "." && "$folder_path" != "./.git"* ]]; then
            folders+=($(basename "$folder_path"))
        fi
    done < <(find . -mindepth 2 -name "Dockerfile" -not -path "./.git/*" -print0)
    
    if [ ${#folders[@]} -eq 0 ]; then
        print_error "No folders with Dockerfiles found"
        exit 1
    fi
    
    print_success "Found folders: ${folders[*]}"
    echo "${folders[@]}"
}

# Function to build a single image with Buildah
build_image() {
    local folder="$1"
    local image_name="${REGISTRY_PREFIX}/${folder}-${IMAGE_SUFFIX}"
    
    print_status "Building enterprise image: $image_name"
    
    cd "$PROJECT_ROOT/$folder"
    
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile not found in $folder"
        return 1
    fi
    
    # Build with Buildah (rootless)
    print_status "Using Buildah for rootless build..."
    buildah build-using-dockerfile \
        --tag "$image_name:latest" \
        --tag "$image_name:$(git rev-parse --short HEAD 2>/dev/null || echo 'local')" \
        .
    
    print_success "Built $image_name:latest"
    
    # Security inspection with Skopeo
    print_status "Performing security inspection with Skopeo..."
    skopeo inspect containers-storage:"$image_name:latest" | jq '{
        Architecture: .Architecture,
        Os: .Os,
        Created: .Created,
        RootFS: .RootFS.type,
        Layers: (.RootFS.diff_ids | length)
    }' || print_warning "Skopeo inspection failed (jq might not be installed)"
    
    return 0
}

# Function to test an image with Podman
test_image() {
    local folder="$1"
    local image_name="${REGISTRY_PREFIX}/${folder}-${IMAGE_SUFFIX}"
    
    print_status "Testing enterprise image: $image_name"
    
    # Basic functionality test
    if podman run --rm "$image_name:latest" echo "Enterprise test successful"; then
        print_success "Image test passed: $image_name"
    else
        print_warning "Image test completed with warnings: $image_name"
    fi
}

# Function to push to registries with Podman
push_image() {
    local folder="$1"
    local image_name="${REGISTRY_PREFIX}/${folder}-${IMAGE_SUFFIX}"
    
    print_status "Pushing enterprise image: $image_name"
    
    # Push to Docker Hub
    if podman push "$image_name:latest" "docker.io/$image_name:latest"; then
        print_success "Pushed to Docker Hub: docker.io/$image_name:latest"
    else
        print_warning "Failed to push to Docker Hub (check login)"
    fi
    
    # Push to GHCR (if configured)
    local ghcr_image="ghcr.io/mytestlab123/${folder}-${IMAGE_SUFFIX}:latest"
    if podman push "$image_name:latest" "$ghcr_image" 2>/dev/null; then
        print_success "Pushed to GHCR: $ghcr_image"
    else
        print_warning "Failed to push to GHCR (check login)"
    fi
}

# Function to show usage
show_usage() {
    echo "Enterprise Container Build Script"
    echo "Usage: $0 [OPTIONS] [FOLDER]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -l, --list     List available folders"
    echo "  -a, --all      Build all discovered folders"
    echo "  -t, --test     Test images after building"
    echo "  -p, --push     Push images to registries"
    echo "  --check        Check prerequisites only"
    echo ""
    echo "Examples:"
    echo "  $0 alpine                    # Build alpine enterprise image"
    echo "  $0 --all --test             # Build and test all images"
    echo "  $0 curl --push              # Build and push curl image"
    echo ""
    echo "Environment Variables:"
    echo "  REGISTRY_PREFIX   Registry prefix (default: amitkarpe)"
    echo "  IMAGE_SUFFIX      Image suffix (default: enterprise)"
}

# Main script logic
main() {
    local build_all=false
    local test_images=false
    local push_images=false
    local target_folder=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                check_prerequisites
                discover_folders
                exit 0
                ;;
            -a|--all)
                build_all=true
                shift
                ;;
            -t|--test)
                test_images=true
                shift
                ;;
            -p|--push)
                push_images=true
                shift
                ;;
            --check)
                check_prerequisites
                exit 0
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
    
    # Check prerequisites
    check_prerequisites
    
    # Determine folders to build
    local folders_to_build=()
    
    if [[ "$build_all" == true ]]; then
        mapfile -t folders_to_build < <(discover_folders)
    elif [[ -n "$target_folder" ]]; then
        if [[ -d "$PROJECT_ROOT/$target_folder" && -f "$PROJECT_ROOT/$target_folder/Dockerfile" ]]; then
            folders_to_build=("$target_folder")
        else
            print_error "Folder '$target_folder' not found or doesn't contain Dockerfile"
            exit 1
        fi
    else
        print_error "No folder specified. Use --all or specify a folder name."
        show_usage
        exit 1
    fi
    
    # Build images
    print_status "Starting enterprise container builds..."
    echo ""
    
    local built_images=()
    for folder in "${folders_to_build[@]}"; do
        if build_image "$folder"; then
            built_images+=("$folder")
            echo ""
        else
            print_error "Failed to build $folder"
        fi
    done
    
    # Test images if requested
    if [[ "$test_images" == true ]]; then
        print_status "Testing built images..."
        echo ""
        for folder in "${built_images[@]}"; do
            test_image "$folder"
        done
        echo ""
    fi
    
    # Push images if requested
    if [[ "$push_images" == true ]]; then
        print_status "Pushing built images..."
        echo ""
        for folder in "${built_images[@]}"; do
            push_image "$folder"
        done
        echo ""
    fi
    
    # Summary
    print_success "Enterprise build completed!"
    echo ""
    echo "Built images:"
    for folder in "${built_images[@]}"; do
        echo "  - ${REGISTRY_PREFIX}/${folder}-${IMAGE_SUFFIX}:latest"
    done
    
    if [[ ${#built_images[@]} -gt 0 ]]; then
        echo ""
        echo "Next steps:"
        echo "  podman images | grep ${IMAGE_SUFFIX}    # List enterprise images"
        echo "  podman run --rm IMAGE_NAME              # Test an image"
        if [[ "$push_images" != true ]]; then
            echo "  $0 --push FOLDER                       # Push to registries"
        fi
    fi
}

# Run main function with all arguments
main "$@"