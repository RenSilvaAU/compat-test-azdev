#!/bin/bash
set -e

PYTHON_VERSION="$1"
OS_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Testing aaz-dev-tools with Python 3.13 built azdev ==="
echo "Python version for aaz-dev-tools: ${PYTHON_VERSION}"
echo "OS: ${OS_NAME}"

# Create virtual environment
python -m venv test_env
source test_env/bin/activate

# Upgrade pip and install build tools
python -m pip install --upgrade pip setuptools wheel

# Install azdev wheel built with Python 3.13
WHEEL_FILE=$(find dist/ -name "azdev-*.whl" | head -n1)
if [ -z "$WHEEL_FILE" ]; then
  echo "Error: No azdev wheel found in dist/"
  echo "Available files in dist/:"
  ls -la dist/ || echo "dist/ directory not found"
  exit 1
fi
echo "Installing Python 3.13 built azdev wheel: $WHEEL_FILE"
python -m pip install "$WHEEL_FILE"

# Install aaz-dev-tools requirements (excluding azdev)
echo "Installing aaz-dev-tools dependencies..."
python -m pip install --only-binary=:all: -r "${SCRIPT_DIR}/requirements.txt"

# Clone and setup aaz-dev-tools
echo "Setting up aaz-dev-tools..."
cd aaz-dev-tools
python -m pip install -e .

# Test that azdev CLI works
echo "Testing azdev CLI commands..."
azdev --version
azdev --help > /dev/null

# Test aaz-dev-tools functionality
echo "Testing aaz-dev-tools with azdev..."
python "${SCRIPT_DIR}/test_aaz_dev_tools.py"

echo "=== aaz-dev-tools compatibility test PASSED with Python 3.13 built azdev on Python ${PYTHON_VERSION} (${OS_NAME}) ==="
