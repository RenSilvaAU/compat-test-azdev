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
& "test_env\Scripts\Activate.ps1"

# Upgrade pip and install build tools
python -m pip install --upgrade pip setuptools wheel

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
python -m pip install $WHEEL_FILE

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
python -m pip install --only-binary=:all: -r $REQUIREMENTS_FILE

# Test that azdev CLI works with aaz-dev-tools requirements
Write-Host "Testing azdev CLI commands..."
python -m azdev --version
python -m azdev --help | Out-Null

# Test aaz-dev-tools requirements imports and compatibility
Write-Host "Testing aaz-dev-tools requirements imports..."
python "$ScriptDir\test_imports.py" $REQUIREMENTS_FILE $PythonVersion $OSName

Write-Host "=== aaz-dev-tools requirements compatibility test PASSED on Python $PythonVersion ($OSName) ==="

# Cleanup
deactivate
Remove-Item -Recurse -Force test_env -ErrorAction SilentlyContinue
Remove-Item temp_aaz_requirements.txt -ErrorAction SilentlyContinue
Write-Host "Testing azdev CLI commands..."
azdev --version
azdev --help | Out-Null

# Test aaz-dev-tools functionality
# Test aaz-dev-tools functionality
Write-Host "Testing aaz-dev-tools with cross-built azdev..."
$testScript = Join-Path $SCRIPT_DIR "test_imports.py"
$requirementsFile = "..\artifacts\cross_aaz_requirements.txt"
& python $testScript $requirementsFile $PYTHON_VERSION $OS_NAME

Write-Host "=== aaz-dev-tools cross-compatibility test PASSED with Python 3.13 built azdev on Python $PythonVersion ($OSName) ==="
