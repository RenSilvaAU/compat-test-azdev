#!/bin/bash
set -e

PYTHON_VERSION="$1"
OS_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Testing azdev compatibility with Python ${PYTHON_VERSION} on ${OS_NAME} ==="

# Create virtual environment
python -m venv test_env
source test_env/bin/activate

# Upgrade pip and install build tools
python -m pip install --upgrade pip setuptools wheel

# Install built azdev wheel
WHEEL_FILE=$(find dist/ -name "azdev-*.whl" | head -n1)
if [ -z "$WHEEL_FILE" ]; then
  echo "Error: No azdev wheel found in dist/"
  echo "Available files in dist/:"
  ls -la dist/ || echo "dist/ directory not found"
  exit 1
fi
echo "Installing azdev wheel: $WHEEL_FILE"
python -m pip install "$WHEEL_FILE"

# Install aaz-dev-tools requirements from shared file
echo "Installing aaz-dev-tools dependencies..."
python -m pip install --only-binary=:all: -r "${SCRIPT_DIR}/requirements.txt"

# Test azdev can be imported and basic functionality works
echo "Testing azdev import and basic functionality..."
python "${SCRIPT_DIR}/test_imports.py" "${SCRIPT_DIR}/requirements.txt" "${PYTHON_VERSION}" "${OS_NAME}"

# Test azdev CLI commands
echo "Testing azdev CLI basic commands..."
azdev --version
azdev --help > /dev/null

echo "=== azdev compatibility test PASSED for Python ${PYTHON_VERSION} on ${OS_NAME} ==="
