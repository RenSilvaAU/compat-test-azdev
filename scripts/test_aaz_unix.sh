#!/bin/bash
set -e

PYTHON_VERSION="$1"
OS_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Testing aaz-dev-tools requirements ==="
echo "Python version: ${PYTHON_VERSION}"
echo "OS: ${OS_NAME}"

# Create virtual environment
rm -rf test_env
python -m venv test_env
source test_env/bin/activate

# Upgrade pip and install build tools (with no-cache to avoid caching issues)
python -m pip install --upgrade --no-cache-dir pip setuptools wheel

# Install azdev wheel (look in all possible locations)
WHEEL_FILE=""
if [ -f "artifacts/azdev-"*.whl ]; then
    WHEEL_FILE=$(find artifacts/ -name "azdev-*.whl" | head -n1)
elif [ -f "artifacts/azure-cli-dev-tools/dist/azdev-"*.whl ]; then
    WHEEL_FILE=$(find artifacts/azure-cli-dev-tools/dist/ -name "azdev-*.whl" | head -n1)
elif [ -f "../artifacts/azdev-"*.whl ]; then
    WHEEL_FILE=$(find ../artifacts/ -name "azdev-*.whl" | head -n1)
elif [ -f "azure-cli-dev-tools/dist/azdev-"*.whl ]; then
    WHEEL_FILE=$(find azure-cli-dev-tools/dist/ -name "azdev-*.whl" | head -n1)
fi

if [ -z "$WHEEL_FILE" ]; then
  echo "Error: No azdev wheel found in artifacts/, artifacts/azure-cli-dev-tools/dist/, ../artifacts/, or azure-cli-dev-tools/dist/"
  echo "Available files in artifacts/:"
  ls -la artifacts/ 2>/dev/null || echo "artifacts/ directory not found"
  echo "Available files in artifacts/azure-cli-dev-tools/dist/:"
  ls -la artifacts/azure-cli-dev-tools/dist/ 2>/dev/null || echo "artifacts/azure-cli-dev-tools/dist/ directory not found"
  echo "Available files in ../artifacts/:"
  ls -la ../artifacts/ 2>/dev/null || echo "../artifacts/ directory not found"
  echo "Available files in azure-cli-dev-tools/dist/:"
  ls -la azure-cli-dev-tools/dist/ 2>/dev/null || echo "azure-cli-dev-tools/dist/ directory not found"
  exit 1
fi
echo "Installing azdev wheel: $WHEEL_FILE"
python -m pip install --no-cache-dir "$WHEEL_FILE"

# Install aaz-dev-tools requirements (look in all possible locations)
REQUIREMENTS_FILE=""
if [ -f "artifacts/cross_aaz_requirements.txt" ]; then
    REQUIREMENTS_FILE="artifacts/cross_aaz_requirements.txt"
elif [ -f "artifacts/scripts/cross_aaz_requirements.txt" ]; then
    REQUIREMENTS_FILE="artifacts/scripts/cross_aaz_requirements.txt"
elif [ -f "../artifacts/cross_aaz_requirements.txt" ]; then
    REQUIREMENTS_FILE="../artifacts/cross_aaz_requirements.txt"
elif [ -f "aaz-dev-tools/requirements.txt" ]; then
    # Create temp requirements file without azdev
    grep -v "^azdev" aaz-dev-tools/requirements.txt > temp_aaz_requirements.txt || true
    REQUIREMENTS_FILE="temp_aaz_requirements.txt"
fi

if [ -z "$REQUIREMENTS_FILE" ] || [ ! -f "$REQUIREMENTS_FILE" ]; then
  echo "Error: No aaz-dev-tools requirements file found"
  exit 1
fi

echo "Installing aaz-dev-tools dependencies from: $REQUIREMENTS_FILE"
python -m pip install --no-cache-dir --only-binary=:all: -r "$REQUIREMENTS_FILE"

# Setup aaz-dev-tools if directory exists
if [ -d "aaz-dev-tools" ]; then
    echo "Setting up aaz-dev-tools..."
    cd aaz-dev-tools
    python -m pip install -e .
    cd ..
fi

# Test that azdev CLI works with aaz-dev-tools requirements
echo "Testing azdev CLI commands..."
python -m azdev --version
python -m azdev --help > /dev/null

# Test aaz-dev-tools functionality
echo "Testing aaz-dev-tools imports..."
python "${SCRIPT_DIR}/test_imports.py" "$REQUIREMENTS_FILE" "${PYTHON_VERSION}" "${OS_NAME}"

echo "=== aaz-dev-tools compatibility test PASSED on Python ${PYTHON_VERSION} (${OS_NAME}) ==="

# Cleanup
deactivate
rm -rf test_env
rm -f temp_aaz_requirements.txt
