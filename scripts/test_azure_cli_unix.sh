#!/bin/bash
set -e

PYTHON_VERSION="$1"
OS_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Testing azure-cli requirements ==="
echo "Python version: ${PYTHON_VERSION}"
echo "OS: ${OS_NAME}"

# Create virtual environment
python -m venv test_env
source test_env/bin/activate

# Upgrade pip and install build tools
python -m pip install --upgrade pip setuptools wheel

# Install azdev wheel (look in both possible locations)
WHEEL_FILE=""
if [ -f "../artifacts/azdev-"*.whl ]; then
    WHEEL_FILE=$(find ../artifacts/ -name "azdev-*.whl" | head -n1)
elif [ -f "azure-cli-dev-tools/dist/azdev-"*.whl ]; then
    WHEEL_FILE=$(find azure-cli-dev-tools/dist/ -name "azdev-*.whl" | head -n1)
fi

if [ -z "$WHEEL_FILE" ]; then
  echo "Error: No azdev wheel found in ../artifacts/ or azure-cli-dev-tools/dist/"
  echo "Available files in ../artifacts/:"
  ls -la ../artifacts/ 2>/dev/null || echo "../artifacts/ directory not found"
  echo "Available files in azure-cli-dev-tools/dist/:"
  ls -la azure-cli-dev-tools/dist/ 2>/dev/null || echo "azure-cli-dev-tools/dist/ directory not found"
  exit 1
fi
echo "Installing azdev wheel: $WHEEL_FILE"
python -m pip install "$WHEEL_FILE"

# Install azure-cli requirements (look in both possible locations)
REQUIREMENTS_FILE=""
if [ -f "../artifacts/cross_azure_cli_requirements.txt" ]; then
    REQUIREMENTS_FILE="../artifacts/cross_azure_cli_requirements.txt"
elif [ -f "azure-cli/requirements.txt" ]; then
    # Create temp requirements file without azdev
    grep -v "^azdev" azure-cli/requirements.txt > temp_azure_cli_requirements.txt || true
    REQUIREMENTS_FILE="temp_azure_cli_requirements.txt"
fi

if [ -z "$REQUIREMENTS_FILE" ] || [ ! -f "$REQUIREMENTS_FILE" ]; then
  echo "Error: No azure-cli requirements file found"
  exit 1
fi

echo "Installing azure-cli dependencies from: $REQUIREMENTS_FILE"
python -m pip install --only-binary=:all: -r "$REQUIREMENTS_FILE"

# Test that azdev CLI works with azure-cli requirements
echo "Testing azdev CLI commands..."
python -m azdev --version
python -m azdev --help > /dev/null

# Test azure-cli requirements imports and compatibility
echo "Testing azure-cli requirements imports..."
python "${SCRIPT_DIR}/test_imports.py" "$REQUIREMENTS_FILE" "${PYTHON_VERSION}" "${OS_NAME}"

echo "=== azure-cli requirements compatibility test PASSED on Python ${PYTHON_VERSION} (${OS_NAME}) ==="

# Cleanup
deactivate
rm -rf test_env
rm -f temp_azure_cli_requirements.txt
