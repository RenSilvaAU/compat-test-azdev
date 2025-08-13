param(
    [Parameter(Mandatory=$true)]
    [string]$PythonVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$OSName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Cross-testing azure-cli requirements with Python 3.13 built azdev ==="
Write-Host "Python version for testing: $PythonVersion"
Write-Host "OS: $OSName"

# Create virtual environment
python -m venv test_env
& "test_env\Scripts\Activate.ps1"

# Upgrade pip and install build tools
python -m pip install --upgrade pip setuptools wheel

# Install azdev wheel built with Python 3.13 first
$WHEEL_FILE = Get-ChildItem -Path "artifacts\" -Name "azdev-*.whl" | Select-Object -First 1
if (-not $WHEEL_FILE) {
    Write-Host "Error: No azdev wheel found in artifacts/"
    Write-Host "Available files in artifacts/:"
    Get-ChildItem -Path "artifacts\" -ErrorAction SilentlyContinue
    exit 1
}
$WHEEL_PATH = "artifacts\$WHEEL_FILE"
Write-Host "Installing Python 3.13 built azdev wheel: $WHEEL_PATH"
python -m pip install $WHEEL_PATH

# Install azure-cli requirements (excluding azdev itself)
Write-Host "Installing azure-cli requirements..."
python -m pip install --only-binary=:all: -r "artifacts\cross_azure_cli_requirements.txt"

# Test that azdev CLI works with azure-cli requirements
Write-Host "Testing azdev CLI commands..."
azdev --version
azdev --help | Out-Null

# Test azure-cli requirements imports and compatibility
Write-Host "Testing azure-cli requirements imports..."
$testScript = Join-Path $ScriptDir "test_imports.py"
$requirementsFile = Join-Path $ScriptDir "..\artifacts\cross_azure_cli_requirements.txt"
& python $testScript $requirementsFile $PythonVersion $OSName

Write-Host "=== azure-cli requirements cross-compatibility test PASSED with Python 3.13 built azdev on Python $PythonVersion ($OSName) ==="
