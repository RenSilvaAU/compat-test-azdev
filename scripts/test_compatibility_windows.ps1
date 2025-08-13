param(
    [Parameter(Mandatory=$true)]
    [string]$PythonVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$OSName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Testing azdev compatibility with Python $PythonVersion on $OSName ==="

# Create virtual environment
python -m venv test_env
& "test_env\Scripts\Activate.ps1"

# Upgrade pip and install build tools
python -m pip install --upgrade pip setuptools wheel

# Install built azdev wheel
$WHEEL_FILE = Get-ChildItem -Path "dist\" -Name "azdev-*.whl" | Select-Object -First 1
if (-not $WHEEL_FILE) {
    Write-Host "Error: No azdev wheel found in dist/"
    Write-Host "Available files in dist/:"
    Get-ChildItem -Path "dist\" -ErrorAction SilentlyContinue
    exit 1
}
$WHEEL_PATH = "dist\$WHEEL_FILE"
Write-Host "Installing azdev wheel: $WHEEL_PATH"
python -m pip install $WHEEL_PATH

# Install aaz-dev-tools requirements from shared file
Write-Host "Installing aaz-dev-tools dependencies..."
python -m pip install --only-binary=:all: -r "$ScriptDir\requirements.txt"

# Test azdev can be imported and basic functionality works
Write-Host "Testing azdev import and basic functionality..."
python "$ScriptDir\test_imports.py"

# Test azdev CLI commands
Write-Host "Testing azdev CLI basic commands..."
azdev --version
azdev --help | Out-Null

Write-Host "=== azdev compatibility test PASSED for Python $PythonVersion on $OSName ==="
