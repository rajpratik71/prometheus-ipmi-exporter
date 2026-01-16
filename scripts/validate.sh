#!/bin/bash

# Local validation script for prometheus-ipmi-exporter release process
# Usage: ./scripts/validate.sh

set -e

echo "🚀 Starting local validation of prometheus-ipmi-exporter release process..."

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check for required tools
command -v go >/dev/null 2>&1 || { echo "❌ Go is required but not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed."; exit 1; }
command -v goreleaser >/dev/null 2>&1 || { echo "❌ Goreleaser is required but not installed."; exit 1; }

# Optional: Check for act (GitHub Actions runner)
if command -v act >/dev/null 2>&1; then
    ACT_AVAILABLE=true
    echo "✅ Act is available for workflow testing"
else
    ACT_AVAILABLE=false
    echo "⚠️  Act not found - workflow testing will be skipped (install from https://github.com/nektos/act)"
fi

# Validate GoReleaser configuration
echo "🔧 Validating GoReleaser configuration..."
goreleaser check

# Run tests
echo "🧪 Running Go tests..."
go test ./...

# Build locally
echo "🏗️  Building locally..."
make build

# Test GoReleaser snapshot
echo "📸 Testing GoReleaser snapshot..."
make test-local

# Test Docker build
echo "🐳 Testing Docker build (standard)..."
make test-docker

# Test Docker buildx
echo "🐳 Testing Docker buildx (multi-arch)..."
make test-docker-buildx

# Test full release process (dry run)
echo "🎯 Testing full release process (dry run)..."
make test-release

# Test GitHub workflows if act is available
if [ "$ACT_AVAILABLE" = true ]; then
    echo "🔄 Testing GitHub workflows locally..."
    make test-workflow
    echo "🔄 Testing release workflow (dry run)..."
    make test-release-workflow
fi

# Validate generated artifacts
echo "📦 Validating generated artifacts..."
if [ -d "dist" ]; then
    echo "✅ Generated artifacts found in dist/"
    ls -la dist/
else
    echo "❌ No dist/ directory found"
    exit 1
fi

# Check Docker images
echo "🖼️  Checking Docker images..."
docker images | grep ipmi-exporter || echo "⚠️  No local ipmi-exporter images found"

echo ""
echo "🎉 Local validation completed successfully!"
echo ""
echo "📝 Summary of what was tested:"
echo "  ✅ GoReleaser configuration"
echo "  ✅ Go tests"
echo "  ✅ Local build"
echo "  ✅ GoReleaser snapshot build"
echo "  ✅ Docker standard build"
echo "  ✅ Docker buildx multi-arch build"
echo "  ✅ Full release process (dry run)"
if [ "$ACT_AVAILABLE" = true ]; then
    echo "  ✅ GitHub workflows"
fi
echo ""
echo "🚀 Ready to push and create a release!"
