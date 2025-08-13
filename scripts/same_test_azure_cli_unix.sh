#!/bin/bash
set -e

PYTHON_VERSION=$1
OS_NAME=$2

echo "Testing azure-cli requirements on $OS_NAME with Python $PYTHON_VERSION"
echo "================================================"

# Check if azure-cli-requirements.txt was prepared
if [ ! -f "azure-cli-requirements.txt" ]; then
    echo "[FAIL] azure-cli-requirements.txt not found"
    exit 1
fi

# Create a virtual environment for testing
python$PYTHON_VERSION -m venv test_azure_cli_env
source test_azure_cli_env/bin/activate

echo "Installing azure-cli requirements..."
pip install --only-binary=:all: -r azure-cli-requirements.txt

# Test importing key azure-cli modules
echo "Testing azure-cli module imports..."
python ../scripts/test_imports.py azure-cli-requirements.txt $PYTHON_VERSION $OS_NAME

# Test basic Azure CLI functionality (if azure-cli package is available)
echo "Testing basic Azure CLI functionality..."
# This is handled by the unified test script above

echo "[OK] Azure CLI requirements test completed successfully on $OS_NAME with Python $PYTHON_VERSION"

# Cleanup
deactivate
rm -rf test_azure_cli_env
