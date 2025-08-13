# Azure CLI Dev Tools - Python Compatibility Testing

This repository contains automated compatibility testing for the Azure CLI Dev Tools (`azdev`) package across multiple Python versions and operating systems.

## Overview

This testing framework validates Python 3.9-3.13 compatibility for `azdev` by testing two key scenarios:
1. **Cross-Python Testing**: Build `azdev` with Python 3.13, test with all Python versions
2. **Same-Python Testing**: Build and test `azdev` with the same Python version

Both scenarios test compatibility with both `aaz-dev-tools` and `azure-cli` dependencies using binary-only installations (`--only-binary=:all:`).

## Test Workflows

### 1. Cross-Python Build and Test

**Workflow**: `cross-python-build-and-test.yml`

**Purpose**: Tests if `azdev` built with Python 3.13 works across all Python versions (3.9-3.13).

**Process**:
1. **Build Phase**: Creates `azdev` wheel using Python 3.13
2. **Test Phase**: Tests the wheel on all Python versions (3.9-3.13) across platforms
3. **Validation**: Ensures cross-version compatibility and binary distribution works

### 2. Same-Python Build and Test  

**Workflow**: `same-python-build-and-test.yml`

**Purpose**: Tests if `azdev` works when built and tested with the same Python version.

**Process**:
1. **Build & Test**: Each Python version builds and tests its own `azdev` wheel
2. **Validation**: Ensures version-specific compatibility and functionality

## Test Coverage

### Platforms
- **Ubuntu Latest**: Linux compatibility testing
- **macOS Latest**: macOS compatibility testing  
- **Windows Latest**: Windows compatibility testing

### Python Versions
- **Python 3.9**: Legacy compatibility
- **Python 3.10**: Stable release compatibility
- **Python 3.11**: Current stable compatibility
- **Python 3.12**: Recent release compatibility
- **Python 3.13**: Latest release compatibility

**Total**: **30 test combinations** per workflow (5 Python versions × 3 platforms × 2 requirement sets)

## What Each Test Does

### AAZ Dev Tools Compatibility Tests

**Scripts**: `test_aaz_unix.sh`, `test_aaz_windows.ps1`

**Purpose**: Validate `azdev` works with `aaz-dev-tools` dependencies

**Test Steps**:
1. **Environment Setup**: Create clean virtual environment
2. **Install azdev**: Install the built `azdev` wheel
3. **Install Dependencies**: Install `aaz-dev-tools` requirements (excluding `azdev` itself)
4. **CLI Testing**: Verify `azdev --version` and `azdev --help` work
5. **Import Testing**: Test all package imports and basic functionality
6. **Cleanup**: Remove test environment

### Azure CLI Requirements Compatibility Tests

**Scripts**: `test_azure_cli_unix.sh`, `test_azure_cli_windows.ps1`

**Purpose**: Validate `azdev` works with `azure-cli` dependencies

**Test Steps**:
1. **Environment Setup**: Create clean virtual environment
2. **Install azdev**: Install the built `azdev` wheel  
3. **Install Dependencies**: Install `azure-cli` requirements (excluding `azdev` itself)
4. **CLI Testing**: Verify `azdev --version` and `azdev --help` work
5. **Import Testing**: Test all package imports and functionality
6. **Cleanup**: Remove test environment

### Import and Functionality Testing

**Script**: `test_imports.py`

**Purpose**: Comprehensive import and functionality validation

**Test Coverage**:
- **Direct Imports**: Tests importing all packages from requirements files
- **Functionality Tests**: Validates basic operations work correctly
- **Error Handling**: Captures and reports import/functionality failures
- **Cross-Platform**: Works on Unix and Windows with appropriate path handling

## Script Architecture

### Unified Test Scripts

All test scripts are **generic** and work for both workflow types:

- **Artifact Detection**: Scripts automatically detect if they're running in:
  - Cross-python scenario (artifacts from build job)
  - Same-python scenario (local build directories)
- **Path Resolution**: Intelligently finds wheels and requirements in multiple locations
- **Platform Compatibility**: Unix scripts use bash, Windows scripts use PowerShell
- **Error Reporting**: Comprehensive error messages with debugging information

### Requirements Handling

- **Dynamic Loading**: Requirements are read from actual source repositories
- **azdev Exclusion**: `azdev` itself is filtered out to avoid conflicts  
- **Binary-Only**: All dependencies installed with `--only-binary=:all:` for consistency
- **Cross-Platform**: Works with both Unix and Windows path conventions

## Usage

### Running Tests via GitHub Actions

#### Cross-Python Testing
1. Go to **Actions** → **Cross-Python Build and Test**
2. Click **"Run workflow"**
3. Configure:
   - **azdev Repository**: `RenSilvaAU/azure-cli-dev-tools` 
   - **azdev Branch**: `resilv/py313azdev`
   - **AAZ Dev Tools Repo**: `RenSilvaAU/aaz-dev-tools`
   - **AAZ Dev Tools Branch**: `resilv/py313`
   - **Azure CLI Repo**: `RenSilvaAU/azure-cli`
   - **Azure CLI Branch**: `resilv/py313cli`
   - **Build Python Version**: `3.13`

#### Same-Python Testing  
1. Go to **Actions** → **Same-Python Build and Test**
2. Click **"Run workflow"** 
3. Configure the same repository settings as above

### Local Testing

You can run the scripts locally for development:

```bash
# Unix/Linux/macOS
chmod +x scripts/test_aaz_unix.sh
./scripts/test_aaz_unix.sh "3.11" "ubuntu-latest"

# Windows PowerShell
scripts\test_aaz_windows.ps1 -PythonVersion "3.11" -OSName "windows-latest"
```

## File Structure

```
compat-test-azdev/
├── .github/workflows/
│   ├── cross-python-build-and-test.yml    # Cross-version compatibility testing
│   └── same-python-build-and-test.yml     # Same-version compatibility testing
├── scripts/
│   ├── test_aaz_unix.sh                    # AAZ dev tools testing (Unix)
│   ├── test_aaz_windows.ps1                # AAZ dev tools testing (Windows)
│   ├── test_azure_cli_unix.sh              # Azure CLI requirements testing (Unix)
│   ├── test_azure_cli_windows.ps1          # Azure CLI requirements testing (Windows)
│   └── test_imports.py                     # Import and functionality validation
└── README.md                               # This documentation
```

## Key Features

- **Automated Testing**: No manual intervention required
- **Comprehensive Coverage**: Tests all Python versions and platforms
- **Binary-Only Dependencies**: Ensures consistent, fast installations
- **Cross-Version Validation**: Verifies forward/backward compatibility
- **Detailed Reporting**: Clear success/failure messages with debugging info
- **Easy Configuration**: Simple workflow inputs for different repositories/branches

## Results

Test results are uploaded as artifacts for each OS/Python combination:
- **Artifact name**: `test-results-{os}-python{version}`
- **Contents**: Virtual environment logs and built wheel files
- **Retention**: 5 days

## Key Features

- **Automated Testing**: No manual intervention required
- **Comprehensive Coverage**: Tests all Python versions and platforms
- **Binary-Only Dependencies**: Ensures consistent, fast installations
- **Cross-Version Validation**: Verifies forward/backward compatibility
- **Detailed Reporting**: Clear success/failure messages with debugging info
- **Easy Configuration**: Simple workflow inputs for different repositories/branches

## Troubleshooting

### Common Issues

1. **"No azdev wheel found"**: Check that the build job completed successfully and artifacts were uploaded
2. **"azdev not recognized"**: Virtual environment issues - scripts use explicit Python paths to avoid this
3. **Import errors**: Dependency conflicts - all tests use `--only-binary=:all:` to ensure consistent packages
4. **Path errors**: Different platforms use different path separators - scripts handle this automatically

### Debugging

- Check the **Actions** tab for detailed logs of each test step
- Each test reports exactly what files it finds and where it looks
- Import testing provides specific error messages for failed imports
- All temporary files are cleaned up, but test logs persist for debugging
