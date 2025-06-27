#!/bin/sh

echo "🌐 Curl Demo Container"
echo "======================"
echo "Built from /curl folder"
echo "Image: amitkarpe/curl-demo:latest"
echo ""

if [ "$#" -eq 0 ]; then
    echo "Usage examples:"
    echo "  docker run amitkarpe/curl-demo https://api.github.com"
    echo "  docker run amitkarpe/curl-demo https://httpbin.org/json"
    echo ""
    echo "Testing default API..."
    echo ""
    curl -s https://httpbin.org/json | jq .
else
    echo "Testing: $1"
    echo ""
    curl -s "$1" | jq . 2>/dev/null || curl -s "$1"
fi