param(
    [Parameter(Mandatory=$true)]
    [string]$PythonVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$OSName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Testing azure-cli requirements ==="
Write-Host "Python version: $PythonVersion"
Write-Host "OS: $OSName"

# Create virtual environment
python -m venv test_env
$PYTHON_EXE = "test_env\Scripts\python.exe"
$PIP_EXE = "test_env\Scripts\pip.exe"

# Upgrade pip and install build tools
& $PIP_EXE install --upgrade pip setuptools wheel

# Install azdev wheel (look in all possible locations)
$WHEEL_FILE = $null
if (Test-Path "artifacts\azdev-*.whl") {
    $WHEEL_FILE = Get-ChildItem -Path "artifacts\" -Filter "azdev-*.whl" | Select-Object -First 1 -ExpandProperty FullName
} elseif (Test-Path "artifacts\azure-cli-dev-tools\dist\azdev-*.whl") {
    $WHEEL_FILE = Get-ChildItem -Path "artifacts\azure-cli-dev-tools\dist\" -Filter "azdev-*.whl" | Select-Object -First 1 -ExpandProperty FullName
} elseif (Test-Path "..\artifacts\azdev-*.whl") {
    $WHEEL_FILE = Get-ChildItem -Path "..\artifacts\" -Filter "azdev-*.whl" | Select-Object -First 1 -ExpandProperty FullName
} elseif (Test-Path "azure-cli-dev-tools\dist\azdev-*.whl") {
    $WHEEL_FILE = Get-ChildItem -Path "azure-cli-dev-tools\dist\" -Filter "azdev-*.whl" | Select-Object -First 1 -ExpandProperty FullName
}

if (-not $WHEEL_FILE) {
    Write-Host "Error: No azdev wheel found in artifacts\, artifacts\azure-cli-dev-tools\dist\, ..\artifacts\, or azure-cli-dev-tools\dist\"
    Write-Host "Available files in artifacts\:"
    Get-ChildItem -Path "artifacts\" -ErrorAction SilentlyContinue
    Write-Host "Available files in artifacts\azure-cli-dev-tools\dist\:"
    Get-ChildItem -Path "artifacts\azure-cli-dev-tools\dist\" -ErrorAction SilentlyContinue
    Write-Host "Available files in ..\artifacts\:"
    Get-ChildItem -Path "..\artifacts\" -ErrorAction SilentlyContinue
    Write-Host "Available files in azure-cli-dev-tools\dist\:"
    Get-ChildItem -Path "azure-cli-dev-tools\dist\" -ErrorAction SilentlyContinue
    exit 1
}
Write-Host "Installing azdev wheel: $WHEEL_FILE"
& $PIP_EXE install $WHEEL_FILE

# Install azure-cli requirements (look in all possible locations)
$REQUIREMENTS_FILE = $null
if (Test-Path "artifacts\cross_azure_cli_requirements.txt") {
    $REQUIREMENTS_FILE = "artifacts\cross_azure_cli_requirements.txt"
} elseif (Test-Path "artifacts\scripts\cross_azure_cli_requirements.txt") {
    $REQUIREMENTS_FILE = "artifacts\scripts\cross_azure_cli_requirements.txt"
} elseif (Test-Path "..\artifacts\cross_azure_cli_requirements.txt") {
    $REQUIREMENTS_FILE = "..\artifacts\cross_azure_cli_requirements.txt"
} elseif (Test-Path "azure-cli\requirements.txt") {
    # Create temp requirements file without azdev
    Get-Content "azure-cli\requirements.txt" | Where-Object { $_ -notmatch "^azdev" } | Set-Content "temp_azure_cli_requirements.txt"
    $REQUIREMENTS_FILE = "temp_azure_cli_requirements.txt"
}

if (-not $REQUIREMENTS_FILE -or -not (Test-Path $REQUIREMENTS_FILE)) {
    Write-Host "Error: No azure-cli requirements file found"
    exit 1
}

Write-Host "Installing azure-cli dependencies from: $REQUIREMENTS_FILE"
& $PIP_EXE install --only-binary=:all: -r $REQUIREMENTS_FILE

# Test that azdev CLI works with azure-cli requirements
Write-Host "Testing azdev CLI commands..."
& $PYTHON_EXE -m azdev --version
& $PYTHON_EXE -m azdev --help | Out-Null

# Test azure-cli requirements imports and compatibility
Write-Host "Testing azure-cli requirements imports..."
& $PYTHON_EXE "$ScriptDir\test_imports.py" $REQUIREMENTS_FILE $PythonVersion $OSName

Write-Host "=== azure-cli requirements compatibility test PASSED on Python $PythonVersion ($OSName) ==="

# Cleanup
deactivate
Remove-Item -Recurse -Force test_env -ErrorAction SilentlyContinue
Remove-Item temp_azure_cli_requirements.txt -ErrorAction SilentlyContinue
Write-Host "Testing azure-cli requirements imports..."
$testScript = Join-Path $ScriptDir "test_imports.py"
$requirementsFile = "..\artifacts\cross_azure_cli_requirements.txt"
& python $testScript $requirementsFile $PythonVersion $OSName

Write-Host "=== azure-cli requirements cross-compatibility test PASSED with Python 3.13 built azdev on Python $PythonVersion ($OSName) ==="
