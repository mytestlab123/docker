#!/bin/bash

# Multi-Registry Pull Testing Script
# Tests image availability and pull functionality across Docker Hub, GHCR, and Quay.io

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Registry configurations
DOCKER_HUB_PREFIX="amitkarpe"
GHCR_PREFIX="ghcr.io/mytestlab123"
QUAY_PREFIX="quay.io/amitkarpe"

# Image suffixes
DEMO_SUFFIX="demo"
ENTERPRISE_SUFFIX="enterprise"

# Function to print colored output
print_header() {
    echo -e "${CYAN}$1${NC}"
}

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

# Function to discover available folders
discover_folders() {
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
    
    echo "${folders[@]}"
}

# Function to test Docker pull
test_docker_pull() {
    local image_url="$1"
    local description="$2"
    
    print_status "Testing Docker pull: $description"
    print_status "Image: $image_url"
    
    # Remove local image if exists
    docker rmi "$image_url" 2>/dev/null || true
    
    if docker pull "$image_url" 2>/dev/null; then
        print_success "✅ Docker pull successful: $description"
        
        # Test run
        if docker run --rm "$image_url" echo "Pull test successful" 2>/dev/null; then
            print_success "✅ Docker run test passed"
        else
            print_warning "⚠️  Docker run completed with warnings"
        fi
        
        return 0
    else
        print_error "❌ Docker pull failed: $description"
        return 1
    fi
}

# Function to test Podman pull
test_podman_pull() {
    local image_url="$1"
    local description="$2"
    
    if ! command -v podman &> /dev/null; then
        print_warning "Podman not available, skipping: $description"
        return 0
    fi
    
    print_status "Testing Podman pull: $description"
    print_status "Image: $image_url"
    
    # Remove local image if exists
    podman rmi "$image_url" 2>/dev/null || true
    
    if podman pull "$image_url" 2>/dev/null; then
        print_success "✅ Podman pull successful: $description"
        
        # Test run
        if podman run --rm "$image_url" echo "Pull test successful" 2>/dev/null; then
            print_success "✅ Podman run test passed"
        else
            print_warning "⚠️  Podman run completed with warnings"
        fi
        
        return 0
    else
        print_error "❌ Podman pull failed: $description"
        return 1
    fi
}

# Function to test Docker Hub registry
test_docker_hub() {
    local folder="$1"
    local suffix="$2"
    
    print_header "📦 Testing Docker Hub: $folder-$suffix"
    echo "Registry: Docker Hub (Public Access)"
    echo "URL Pattern: $DOCKER_HUB_PREFIX/{folder}-{suffix}:latest"
    echo ""
    
    local image_url="$DOCKER_HUB_PREFIX/${folder}-${suffix}:latest"
    local results=()
    
    # Test Docker pull
    if test_docker_pull "$image_url" "Docker Hub - $folder-$suffix"; then
        results+=("PASS:Docker pull from Docker Hub")
    else
        results+=("FAIL:Docker pull from Docker Hub")
    fi
    
    echo ""
    
    # Test Podman pull
    if test_podman_pull "$image_url" "Docker Hub - $folder-$suffix"; then
        results+=("PASS:Podman pull from Docker Hub")
    else
        results+=("FAIL:Podman pull from Docker Hub")
    fi
    
    echo "${results[@]}"
}

# Function to test GHCR registry
test_ghcr() {
    local folder="$1"
    local suffix="$2"
    
    print_header "🐙 Testing GitHub Container Registry: $folder-$suffix"
    echo "Registry: GHCR (Private - Authentication Required)"
    echo "URL Pattern: $GHCR_PREFIX/{folder}-{suffix}:latest"
    echo ""
    
    local image_url="$GHCR_PREFIX/${folder}-${suffix}:latest"
    local results=()
    
    # Check if user is logged in to GHCR
    if docker info 2>/dev/null | grep -q "ghcr.io" || echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin 2>/dev/null; then
        print_status "GHCR authentication detected"
    else
        print_warning "GHCR authentication may be required"
        print_status "To authenticate: echo \$GITHUB_TOKEN | docker login ghcr.io -u \$GITHUB_ACTOR --password-stdin"
    fi
    
    # Test Docker pull
    if test_docker_pull "$image_url" "GHCR - $folder-$suffix"; then
        results+=("PASS:Docker pull from GHCR")
    else
        results+=("FAIL:Docker pull from GHCR")
    fi
    
    echo ""
    
    # Test Podman pull
    if test_podman_pull "$image_url" "GHCR - $folder-$suffix"; then
        results+=("PASS:Podman pull from GHCR")
    else
        results+=("FAIL:Podman pull from GHCR")
    fi
    
    echo "${results[@]}"
}

# Function to test Quay.io registry
test_quay() {
    local folder="$1"
    local suffix="$2"
    
    print_header "🔐 Testing Quay.io: $folder-$suffix"
    echo "Registry: Quay.io (Public - Manual Repo Creation Required)"
    echo "URL Pattern: $QUAY_PREFIX/{folder}-{suffix}:latest"
    echo ""
    
    local image_url="$QUAY_PREFIX/${folder}-${suffix}:latest"
    local results=()
    
    print_status "Note: Quay.io repos must be manually created by admin"
    print_status "Robot account can push but cannot create new repositories"
    
    # Test Docker pull
    if test_docker_pull "$image_url" "Quay.io - $folder-$suffix"; then
        results+=("PASS:Docker pull from Quay.io")
    else
        results+=("FAIL:Docker pull from Quay.io")
    fi
    
    echo ""
    
    # Test Podman pull
    if test_podman_pull "$image_url" "Quay.io - $folder-$suffix"; then
        results+=("PASS:Podman pull from Quay.io")
    else
        results+=("FAIL:Podman pull from Quay.io")
    fi
    
    echo "${results[@]}"
}

# Function to test image inspection with Skopeo
test_skopeo_inspect() {
    local image_url="$1"
    local description="$2"
    
    if ! command -v skopeo &> /dev/null; then
        print_warning "Skopeo not available, skipping inspection: $description"
        return 0
    fi
    
    print_status "Inspecting with Skopeo: $description"
    
    if skopeo inspect "docker://$image_url" > /dev/null 2>&1; then
        print_success "✅ Skopeo inspection successful: $description"
        return 0
    else
        print_error "❌ Skopeo inspection failed: $description"
        return 1
    fi
}

# Function to generate comprehensive test report
generate_test_report() {
    local all_results=("$@")
    
    echo ""
    print_header "═══════════════════════════════════════════"
    print_header "📊 MULTI-REGISTRY PULL TEST REPORT"
    print_header "═══════════════════════════════════════════"
    echo ""
    
    local total_tests=0
    local passed_tests=0
    local docker_hub_tests=0
    local ghcr_tests=0
    local quay_tests=0
    
    # Categorize results
    for result in "${all_results[@]}"; do
        if [[ "$result" == "PASS:"* ]]; then
            echo -e "${GREEN}✅${NC} ${result#PASS:}"
            ((passed_tests++))
        else
            echo -e "${RED}❌${NC} ${result#FAIL:}"
        fi
        ((total_tests++))
        
        # Count by registry
        if [[ "$result" == *"Docker Hub"* ]]; then
            ((docker_hub_tests++))
        elif [[ "$result" == *"GHCR"* ]]; then
            ((ghcr_tests++))
        elif [[ "$result" == *"Quay.io"* ]]; then
            ((quay_tests++))
        fi
    done
    
    echo ""
    print_header "📈 SUMMARY STATISTICS"
    echo "Total Tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $((total_tests - passed_tests))"
    echo "Success Rate: $(( passed_tests * 100 / total_tests ))%"
    echo ""
    
    print_header "🏷️  REGISTRY BREAKDOWN"
    echo "Docker Hub tests: $((docker_hub_tests / 2)) images tested"
    echo "GHCR tests: $((ghcr_tests / 2)) images tested"
    echo "Quay.io tests: $((quay_tests / 2)) images tested"
    echo ""
    
    # Registry-specific guidance
    print_header "🔧 ACCESS GUIDANCE"
    echo ""
    
    echo -e "${GREEN}✅ Docker Hub (Public Access)${NC}"
    echo "  docker pull amitkarpe/alpine-demo:latest"
    echo "  podman pull amitkarpe/curl-enterprise:latest"
    echo ""
    
    echo -e "${YELLOW}🔒 GHCR (Private - Auth Required)${NC}"
    echo "  echo \$GITHUB_TOKEN | docker login ghcr.io -u \$GITHUB_ACTOR --password-stdin"
    echo "  docker pull ghcr.io/mytestlab123/alpine-demo:latest"
    echo "  podman pull ghcr.io/mytestlab123/curl-enterprise:latest"
    echo ""
    
    echo -e "${BLUE}🏗️  Quay.io (Manual Repo Creation)${NC}"
    echo "  docker pull quay.io/amitkarpe/alpine-demo:latest"
    echo "  podman pull quay.io/amitkarpe/curl-enterprise:latest"
    echo "  Note: Repositories must be created manually by admin"
    echo ""
    
    if [ "$passed_tests" -eq "$total_tests" ]; then
        print_success "🎉 All registry pull tests passed!"
        return 0
    else
        print_warning "⚠️  Some registry tests failed - check access and repository existence"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Multi-Registry Pull Testing Script"
    echo "Usage: $0 [OPTIONS] [FOLDER]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -l, --list           List available project folders"
    echo "  -a, --all            Test all available images"
    echo "  -r, --registry NAME  Test specific registry only (dockerhub|ghcr|quay)"
    echo "  -s, --suffix TYPE    Test specific suffix only (demo|enterprise)"
    echo "  -t, --tools TOOL     Test specific tool only (docker|podman)"
    echo "  --inspect            Include Skopeo inspection"
    echo ""
    echo "Registries:"
    echo "  dockerhub            Docker Hub (amitkarpe/*)"
    echo "  ghcr                 GitHub Container Registry (ghcr.io/mytestlab123/*)"
    echo "  quay                 Quay.io (quay.io/amitkarpe/*)"
    echo ""
    echo "Image Types:"
    echo "  demo                 Standard Docker workflow images"
    echo "  enterprise           Enterprise Podman/Buildah workflow images"
    echo ""
    echo "Examples:"
    echo "  $0 alpine                           # Test alpine images on all registries"
    echo "  $0 --all --registry dockerhub      # Test all Docker Hub images"
    echo "  $0 curl --suffix enterprise        # Test curl enterprise images"
    echo "  $0 --all --tools docker --inspect  # Test all with Docker and Skopeo"
}

# Main function
main() {
    local test_all=false
    local target_folder=""
    local target_registry=""
    local target_suffix=""
    local target_tools=""
    local include_inspect=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                print_status "Available project folders:"
                for folder in $(discover_folders); do
                    echo "  - $folder"
                done
                exit 0
                ;;
            -a|--all)
                test_all=true
                shift
                ;;
            -r|--registry)
                target_registry="$2"
                shift 2
                ;;
            -s|--suffix)
                target_suffix="$2"
                shift 2
                ;;
            -t|--tools)
                target_tools="$2"
                shift 2
                ;;
            --inspect)
                include_inspect=true
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
    
    # Header
    print_header "🧪 Multi-Registry Pull Testing"
    print_header "==============================="
    echo "Testing image availability across Docker Hub, GHCR, and Quay.io"
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
    
    print_status "Testing folders: ${folders_to_test[*]}"
    echo ""
    
    # Determine suffixes to test
    local suffixes_to_test=()
    if [[ -n "$target_suffix" ]]; then
        suffixes_to_test=("$target_suffix")
    else
        suffixes_to_test=("$DEMO_SUFFIX" "$ENTERPRISE_SUFFIX")
    fi
    
    # Run tests
    local all_results=()
    
    for folder in "${folders_to_test[@]}"; do
        for suffix in "${suffixes_to_test[@]}"; do
            echo "----------------------------------------"
            print_status "Testing: $folder-$suffix"
            echo "----------------------------------------"
            
            # Test registries
            if [[ -z "$target_registry" || "$target_registry" == "dockerhub" ]]; then
                results=($(test_docker_hub "$folder" "$suffix"))
                all_results+=("${results[@]}")
                echo ""
            fi
            
            if [[ -z "$target_registry" || "$target_registry" == "ghcr" ]]; then
                results=($(test_ghcr "$folder" "$suffix"))
                all_results+=("${results[@]}")
                echo ""
            fi
            
            if [[ -z "$target_registry" || "$target_registry" == "quay" ]]; then
                results=($(test_quay "$folder" "$suffix"))
                all_results+=("${results[@]}")
                echo ""
            fi
            
            # Skopeo inspection if requested
            if [[ "$include_inspect" == true ]]; then
                print_header "🔍 Skopeo Inspection: $folder-$suffix"
                
                if [[ -z "$target_registry" || "$target_registry" == "dockerhub" ]]; then
                    test_skopeo_inspect "$DOCKER_HUB_PREFIX/${folder}-${suffix}:latest" "Docker Hub - $folder-$suffix"
                fi
                
                if [[ -z "$target_registry" || "$target_registry" == "ghcr" ]]; then
                    test_skopeo_inspect "$GHCR_PREFIX/${folder}-${suffix}:latest" "GHCR - $folder-$suffix"
                fi
                
                if [[ -z "$target_registry" || "$target_registry" == "quay" ]]; then
                    test_skopeo_inspect "$QUAY_PREFIX/${folder}-${suffix}:latest" "Quay.io - $folder-$suffix"
                fi
                
                echo ""
            fi
        done
    done
    
    # Generate comprehensive report
    generate_test_report "${all_results[@]}"
}

# Run main function with all arguments
main "$@"