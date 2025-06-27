#!/bin/bash

echo "🏔️  Alpine Demo Container"
echo "========================="
echo "Built from /alpine folder"
echo "Image: amitkarpe/alpine-demo:latest"
echo ""
echo "System Info:"
echo "- OS: Alpine Linux $(cat /etc/alpine-release)"
echo "- Shell: $(echo $SHELL)"
echo "- Architecture: $(uname -m)"
echo ""
echo "Available tools: curl, wget, bash, jq"
echo ""
echo "Lightweight container ready! ⚡ (Multi-registry test)"

# Keep container running
tail -f /dev/null