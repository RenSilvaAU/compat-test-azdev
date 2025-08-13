#!/bin/bash
set -e

PYTHON_VE# Install azure-cli requirements (excluding azdev itself)
echo "Installing azure-cli requirements..."
python -m pip install --only-binary=:all: -r "../artifacts/cross_azure_cli_requirements.txt"ON="$1"
OS_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Cross-testing azure-cli requirements with Python 3.13 built azdev ==="
echo "Python version for testing: ${PYTHON_VERSION}"
echo "OS: ${OS_NAME}"

# Create virtual environment
python -m venv test_env
source test_env/bin/activate

# Upgrade pip and install build tools
python -m pip install --upgrade pip setuptools wheel

# Install azdev wheel built with Python 3.13 first
WHEEL_FILE=$(find ../artifacts/ -name "azdev-*.whl" | head -n1)
if [ -z "$WHEEL_FILE" ]; then
  echo "Error: No azdev wheel found in ../artifacts/"
  echo "Available files in ../artifacts/:"
  ls -la ../artifacts/ || echo "../artifacts/ directory not found"
  exit 1
fi
echo "Installing Python 3.13 built azdev wheel: $WHEEL_FILE"
python -m pip install "$WHEEL_FILE"

# Install azure-cli requirements (excluding azdev itself)
echo "Installing azure-cli requirements..."
python -m pip install --only-binary=:all: -r artifacts/cross_azure_cli_requirements.txt

# Test that azdev CLI works with azure-cli requirements
echo "Testing azdev CLI commands..."
azdev --version
azdev --help > /dev/null

# Test azure-cli requirements imports and compatibility
echo "Testing azure-cli requirements imports..."
# Test azure-cli functionality
echo "Testing azure-cli with cross-built azdev..."
python "${SCRIPT_DIR}/test_imports.py" "../artifacts/cross_azure_cli_requirements.txt" "${PYTHON_VERSION}" "${OS_NAME}"

echo "=== azure-cli requirements cross-compatibility test PASSED with Python 3.13 built azdev on Python ${PYTHON_VERSION} (${OS_NAME}) ==="
