param(
    [Parameter(Mandatory=$true)]
    [string]$PythonVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$OSName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Testing aaz-dev-tools requirements ==="
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
} elseif (Test-Path "..\artifacts\azdev-*.whl") {
    $WHEEL_FILE = Get-ChildItem -Path "..\artifacts\" -Filter "azdev-*.whl" | Select-Object -First 1 -ExpandProperty FullName
} elseif (Test-Path "azure-cli-dev-tools\dist\azdev-*.whl") {
    $WHEEL_FILE = Get-ChildItem -Path "azure-cli-dev-tools\dist\" -Filter "azdev-*.whl" | Select-Object -First 1 -ExpandProperty FullName
}

if (-not $WHEEL_FILE) {
    Write-Host "Error: No azdev wheel found in artifacts\, ..\artifacts\, or azure-cli-dev-tools\dist\"
    Write-Host "Available files in artifacts\:"
    Get-ChildItem -Path "artifacts\" -ErrorAction SilentlyContinue
    Write-Host "Available files in ..\artifacts\:"
    Get-ChildItem -Path "..\artifacts\" -ErrorAction SilentlyContinue
    Write-Host "Available files in azure-cli-dev-tools\dist\:"
    Get-ChildItem -Path "azure-cli-dev-tools\dist\" -ErrorAction SilentlyContinue
    exit 1
}
Write-Host "Installing azdev wheel: $WHEEL_FILE"
& $PIP_EXE install $WHEEL_FILE

# Install aaz-dev-tools requirements (look in all possible locations)
$REQUIREMENTS_FILE = $null
if (Test-Path "artifacts\cross_aaz_requirements.txt") {
    $REQUIREMENTS_FILE = "artifacts\cross_aaz_requirements.txt"
} elseif (Test-Path "..\artifacts\cross_aaz_requirements.txt") {
    $REQUIREMENTS_FILE = "..\artifacts\cross_aaz_requirements.txt"
} elseif (Test-Path "aaz-dev-tools\requirements.txt") {
    # Create temp requirements file without azdev
    Get-Content "aaz-dev-tools\requirements.txt" | Where-Object { $_ -notmatch "^azdev" } | Set-Content "temp_aaz_requirements.txt"
    $REQUIREMENTS_FILE = "temp_aaz_requirements.txt"
}

if (-not $REQUIREMENTS_FILE -or -not (Test-Path $REQUIREMENTS_FILE)) {
    Write-Host "Error: No aaz-dev-tools requirements file found"
    exit 1
}

Write-Host "Installing aaz-dev-tools dependencies from: $REQUIREMENTS_FILE"
& $PIP_EXE install --only-binary=:all: -r $REQUIREMENTS_FILE

# Test that azdev CLI works with aaz-dev-tools requirements
Write-Host "Testing azdev CLI commands..."
& $PYTHON_EXE -m azdev --version
& $PYTHON_EXE -m azdev --help | Out-Null

# Test aaz-dev-tools requirements imports and compatibility
Write-Host "Testing aaz-dev-tools requirements imports..."
& $PYTHON_EXE "$ScriptDir\test_imports.py" $REQUIREMENTS_FILE $PythonVersion $OSName

Write-Host "=== aaz-dev-tools requirements compatibility test PASSED on Python $PythonVersion ($OSName) ==="

# Cleanup
Remove-Item -Recurse -Force test_env -ErrorAction SilentlyContinue
Remove-Item temp_aaz_requirements.txt -ErrorAction SilentlyContinue
