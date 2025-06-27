#!/bin/bash

# Quick Quay.io Credentials Test
# Quickly verifies that Quay.io credentials work with a simple alpine test

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
QUAY_USERNAME="${QUAY_USERNAME:-amitkarpe}"
TEST_IMAGE="quay.io/$QUAY_USERNAME/quick-test:$(date +%s)"

echo -e "${BLUE}🚀 Quick Quay.io Credentials Test${NC}"
echo "================================="
echo "Username: $QUAY_USERNAME"
echo "Test Image: $TEST_IMAGE"
echo ""

# Step 1: Test login (user should already be logged in)
echo -e "${BLUE}[1/4]${NC} Checking Docker login status..."
if docker info | grep -q "Registry"; then
    echo -e "${GREEN}✅ Docker appears to be logged in${NC}"
else
    echo -e "${YELLOW}⚠️  Docker login status unclear${NC}"
fi

# Step 2: Build simple test image
echo -e "${BLUE}[2/4]${NC} Building simple test image..."
docker run --rm alpine:latest echo "Alpine test" > /dev/null
if docker tag alpine:latest "$TEST_IMAGE"; then
    echo -e "${GREEN}✅ Test image tagged successfully${NC}"
else
    echo -e "${RED}❌ Failed to tag test image${NC}"
    exit 1
fi

# Step 3: Push to Quay.io
echo -e "${BLUE}[3/4]${NC} Testing push to Quay.io..."
if docker push "$TEST_IMAGE"; then
    echo -e "${GREEN}✅ Push to Quay.io successful!${NC}"
else
    echo -e "${RED}❌ Push to Quay.io failed${NC}"
    echo ""
    echo "Possible issues:"
    echo "1. Not logged in to Quay.io (run: docker login quay.io)"
    echo "2. Incorrect credentials"
    echo "3. Repository permissions"
    echo ""
    echo "To login manually:"
    echo "  docker login -u=\"$QUAY_USERNAME\" quay.io"
    exit 1
fi

# Step 4: Test pull and run
echo -e "${BLUE}[4/4]${NC} Testing pull and run..."
docker rmi "$TEST_IMAGE" 2>/dev/null || true
if docker pull "$TEST_IMAGE" && docker run --rm "$TEST_IMAGE" echo "Quay.io test successful"; then
    echo -e "${GREEN}✅ Pull and run successful!${NC}"
else
    echo -e "${RED}❌ Pull or run failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All Quay.io credential tests passed!${NC}"
echo ""
echo "✅ Docker login to Quay.io: Working"
echo "✅ Push to Quay.io: Working"  
echo "✅ Pull from Quay.io: Working"
echo "✅ Image execution: Working"
echo ""
echo -e "${BLUE}Ready for GitHub Actions integration!${NC}"

# Cleanup
echo ""
echo -e "${YELLOW}Cleaning up test image...${NC}"
docker rmi "$TEST_IMAGE" 2>/dev/null || true
echo -e "${GREEN}✅ Cleanup completed${NC}"