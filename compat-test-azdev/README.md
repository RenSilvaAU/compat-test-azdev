# Azure CLI Dev Tools - Python Compatibility Testing

This repository contains automated compatibility testing for the Azure CLI Dev Tools (`azdev`) package across multiple Python versions and operating systems.

## Overview

This testing framework:
- Builds the `azdev` package from source 
- Tests compatibility with `aaz-dev-tools` dependencies
- Validates functionality across Python 3.9-3.13 on Ubuntu, macOS, and Windows
- Uses binary-only installations (`--only-binary=:all:`) for dependency management

## Usage

### Running Tests via GitHub Actions

1. **Navigate to the Actions tab** in your GitHub repository
2. **Select "Python Compatibility Test"** workflow
3. **Click "Run workflow"** and configure:
   - **Azure CLI Dev Tools repository**: `owner/repo` (e.g., `Azure/azure-cli-dev-tools`)
   - **Branch to test**: The branch containing your changes (e.g., `dev`, `main`)
   - **AAZ Dev Tools repository**: `owner/repo` for requirements source (e.g., `Azure/aaz-dev-tools`) 
   - **AAZ Dev Tools branch**: Branch to get requirements from (e.g., `main`)

4. **Click "Run workflow"** to start the test matrix

### Test Matrix

The workflow tests all combinations of:
- **Operating Systems**: Ubuntu (latest), macOS (latest), Windows (latest)
- **Python Versions**: 3.9, 3.10, 3.11, 3.12, 3.13

Total: **15 test combinations** per workflow run

## What Gets Tested

1. **Package Building**: Creates wheel from `azure-cli-dev-tools` source
2. **Installation**: Installs the built wheel in clean virtual environments  
3. **Dependency Compatibility**: Installs `aaz-dev-tools` requirements using `--only-binary=:all:`
4. **Import Testing**: Verifies `azdev` and core modules can be imported
5. **Basic Functionality**: Tests basic CLI commands (`azdev --version`, `azdev --help`)
6. **Dependency Resolution**: Ensures no version conflicts with `aaz-dev-tools` dependencies

## Test Scripts

- **`scripts/test_compatibility_unix.sh`**: Unix/Linux/macOS compatibility testing
- **`scripts/test_compatibility_windows.ps1`**: Windows PowerShell compatibility testing  
- **`scripts/test_imports.py`**: Python import and dependency validation
- **`scripts/requirements.txt`**: Template requirements file (replaced during workflow)

## Results

Test results are uploaded as artifacts for each OS/Python combination:
- **Artifact name**: `test-results-{os}-python{version}`
- **Contents**: Virtual environment logs and built wheel files
- **Retention**: 5 days

## Local Testing

To run tests locally:

```bash
# Clone repositories
git clone https://github.com/Azure/azure-cli-dev-tools.git
git clone https://github.com/Azure/aaz-dev-tools.git

# Build azdev
cd azure-cli-dev-tools
python -m build --wheel

# Copy requirements
cp ../aaz-dev-tools/requirements.txt ../compat-test/scripts/

# Run test (Unix/macOS)
chmod +x ../compat-test/scripts/test_compatibility_unix.sh
../compat-test/scripts/test_compatibility_unix.sh "3.11" "local"
```

## Notes

- All dependencies are installed using `--only-binary=:all:` to ensure consistent binary package usage
- Tests are isolated in separate virtual environments for each run
- The workflow can be triggered manually with custom repository and branch parameters
- No modifications are made to the source `azure-cli-dev-tools` or `aaz-dev-tools` repositories
