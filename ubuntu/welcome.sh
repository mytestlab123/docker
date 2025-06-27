#!/bin/bash

echo "🐧 Ubuntu Demo Container"
echo "========================="
echo "Built from /ubuntu folder"
echo "Image: amitkarpe/ubuntu-demo:latest"
echo ""
echo "System Info:"
echo "- OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "- Kernel: $(uname -r)"
echo "- Architecture: $(uname -m)"
echo ""
echo "Available tools: curl, wget, vim, htop"
echo ""
echo "Container is ready! 🎉"

# Keep container running
tail -f /dev/null