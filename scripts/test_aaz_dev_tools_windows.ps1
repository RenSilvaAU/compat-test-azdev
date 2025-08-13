param(
    [Parameter(Mandatory=$true)]
    [string]$PythonVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$OSName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Testing aaz-dev-tools with Python 3.13 built azdev ==="
Write-Host "Python version for aaz-dev-tools: $PythonVersion"
Write-Host "OS: $OSName"

# Create virtual environment
python -m venv test_env
& "test_env\Scripts\Activate.ps1"

# Upgrade pip and install build tools
python -m pip install --upgrade pip setuptools wheel

# Install azdev wheel built with Python 3.13
$WHEEL_FILE = Get-ChildItem -Path "dist\" -Name "azdev-*.whl" | Select-Object -First 1
if (-not $WHEEL_FILE) {
    Write-Host "Error: No azdev wheel found in dist/"
    Write-Host "Available files in dist/:"
    Get-ChildItem -Path "dist\" -ErrorAction SilentlyContinue
    exit 1
}
$WHEEL_PATH = "dist\$WHEEL_FILE"
Write-Host "Installing Python 3.13 built azdev wheel: $WHEEL_PATH"
python -m pip install $WHEEL_PATH

# Install aaz-dev-tools requirements (excluding azdev)
Write-Host "Installing aaz-dev-tools dependencies..."
python -m pip install --only-binary=:all: -r "$ScriptDir\requirements.txt"

# Clone and setup aaz-dev-tools
Write-Host "Setting up aaz-dev-tools..."
Set-Location aaz-dev-tools
python -m pip install -e .

# Test that azdev CLI works
Write-Host "Testing azdev CLI commands..."
azdev --version
azdev --help | Out-Null

# Test aaz-dev-tools functionality
Write-Host "Testing aaz-dev-tools with azdev..."
python "$ScriptDir\test_aaz_dev_tools.py"

Write-Host "=== aaz-dev-tools compatibility test PASSED with Python 3.13 built azdev on Python $PythonVersion ($OSName) ==="
