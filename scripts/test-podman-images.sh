#!/bin/bash

# Podman Image Testing Script
# Tests all available container images using Podman

set -e

echo "🐳 Testing Container Images with Podman"
echo "========================================"

IMAGES=("alpine-demo" "curl-demo")
REGISTRIES=("docker.io/amitkarpe" "ghcr.io/mytestlab123")
FAILED_TESTS=0

# Function to test image availability from multiple registries
test_image_pull() {
    local image=$1
    local registry=$2
    echo "📥 Testing pull: ${registry}/${image}:latest"
    
    if podman pull "${registry}/${image}:latest" > /dev/null 2>&1; then
        echo "✅ Pull successful: ${registry}/${image}"
        return 0
    else
        echo "❌ Pull failed: ${registry}/${image}"
        return 1
    fi
}

# Function to test basic image functionality
test_image_run() {
    local image=$1
    echo "🏃 Testing run: ${REGISTRY}/${image}:latest"
    
    if podman run --rm "${REGISTRY}/${image}:latest" echo "Test successful" > /dev/null 2>&1; then
        echo "✅ Run successful: ${image}"
        return 0
    else
        echo "❌ Run failed: ${image}"
        return 1
    fi
}

# Function to test specific image functionality
test_alpine_functionality() {
    echo "🏔️  Testing Alpine functionality..."
    
    # Test jq is available
    if podman run --rm "${REGISTRY}/alpine-demo:latest" jq --version > /dev/null 2>&1; then
        echo "✅ jq available in alpine-demo"
    else
        echo "❌ jq not available in alpine-demo"
        ((FAILED_TESTS++))
    fi
    
    # Test curl is available
    if podman run --rm "${REGISTRY}/alpine-demo:latest" curl --version > /dev/null 2>&1; then
        echo "✅ curl available in alpine-demo"
    else
        echo "❌ curl not available in alpine-demo"
        ((FAILED_TESTS++))
    fi
}

test_curl_functionality() {
    echo "🌐 Testing Curl functionality..."
    
    # Test default behavior
    if podman run --rm "${REGISTRY}/curl-demo:latest" > /dev/null 2>&1; then
        echo "✅ curl-demo default behavior works"
    else
        echo "❌ curl-demo default behavior failed"
        ((FAILED_TESTS++))
    fi
    
    # Test with specific URL
    if podman run --rm "${REGISTRY}/curl-demo:latest" https://httpbin.org/json > /dev/null 2>&1; then
        echo "✅ curl-demo with URL works"
    else
        echo "❌ curl-demo with URL failed"
        ((FAILED_TESTS++))
    fi
}

# Test performance
test_performance() {
    echo "⚡ Testing performance..."
    
    for image in "${IMAGES[@]}"; do
        echo "Testing startup time for ${image}..."
        start_time=$(date +%s.%N)
        podman run --rm "${REGISTRY}/${image}:latest" echo "ready" > /dev/null 2>&1
        end_time=$(date +%s.%N)
        startup_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
        echo "⏱️  ${image} startup time: ${startup_time}s"
    done
}

# Test security (rootless execution)
test_security() {
    echo "🔒 Testing security (rootless execution)..."
    
    for image in "${IMAGES[@]}"; do
        user_info=$(podman run --rm "${REGISTRY}/${image}:latest" id 2>/dev/null || echo "unknown")
        echo "👤 ${image} runs as: ${user_info}"
    done
}

# Main testing loop
echo "🧪 Starting comprehensive tests..."
echo ""

for registry in "${REGISTRIES[@]}"; do
    echo "========================================"
    echo "Testing Registry: ${registry}"
    echo "========================================"
    
    for image in "${IMAGES[@]}"; do
        echo "----------------------------------------"
        echo "Testing: ${registry}/${image}:latest"
        echo "----------------------------------------"
        
        # Test pull
        if ! test_image_pull "$image" "$registry"; then
            ((FAILED_TESTS++))
            continue
        fi
        
        # Test basic run (using first successful pull)
        if ! test_image_run "${registry}/${image}"; then
            ((FAILED_TESTS++))
            continue
        fi
        
        # Show image info
        echo "📊 Image information:"
        podman images "${registry}/${image}:latest" --format "table {{.Repository}} {{.Tag}} {{.Size}} {{.CreatedAt}}" 2>/dev/null || echo "Image info unavailable"
        
        echo ""
    done
    echo ""
done

# Test specific functionality
echo "========================================="
echo "Testing specific functionality"
echo "========================================="

test_alpine_functionality
test_curl_functionality

# Performance tests
echo ""
echo "========================================="
echo "Performance and Security Tests"
echo "========================================="

test_performance
test_security

# Network test
echo ""
echo "🌐 Testing network connectivity..."
if podman run --rm "${REGISTRY}/curl-demo:latest" https://httpbin.org/json > /dev/null 2>&1; then
    echo "✅ Network connectivity test passed"
else
    echo "❌ Network connectivity test failed"
    ((FAILED_TESTS++))
fi

# Clean up any remaining containers
echo ""
echo "🧹 Cleaning up..."
podman container prune -f > /dev/null 2>&1 || true

# Final results
echo ""
echo "========================================="
echo "Test Results Summary"
echo "========================================="

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 All tests passed! All images are working correctly."
    echo ""
    echo "📋 Available images:"
    for registry in "${REGISTRIES[@]}"; do
        echo "  Registry: ${registry}"
        for image in "${IMAGES[@]}"; do
            echo "    podman pull ${registry}/${image}:latest"
        done
        echo ""
    done
    echo ""
    echo "🚀 Ready for production use!"
    exit 0
else
    echo "❌ ${FAILED_TESTS} test(s) failed."
    echo "Please check the logs above for details."
    exit 1
fi