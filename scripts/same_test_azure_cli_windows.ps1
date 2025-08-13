param(
    [Parameter(Mandatory=$true)]
    [string]$PythonVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$OSName
)

Write-Host "Testing azure-cli requirements on $OSName with Python $PythonVersion"
Write-Host "================================================"

# Check if azure-cli-requirements.txt was prepared
if (-not (Test-Path "azure-cli-requirements.txt")) {
    Write-Host "[FAIL] azure-cli-requirements.txt not found"
    exit 1
}

# Create a virtual environment for testing
& python -m venv test_azure_cli_env
& .\test_azure_cli_env\Scripts\Activate.ps1

Write-Host "Installing azure-cli requirements..."
& pip install --only-binary=:all: -r azure-cli-requirements.txt

# Test importing key azure-cli modules
Write-Host "Testing azure-cli module imports..."
& python ..\scripts\test_imports.py azure-cli-requirements.txt $PythonVersion $OSName

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Azure CLI module import test failed"
    deactivate
    Remove-Item -Recurse -Force test_azure_cli_env
    exit 1
}

# Test basic Azure CLI functionality (if azure-cli package is available)
Write-Host "Testing basic Azure CLI functionality..."
# This is handled by the unified test script above

Write-Host "[OK] Azure CLI requirements test completed successfully on $OSName with Python $PythonVersion"

# Cleanup
deactivate
Remove-Item -Recurse -Force test_azure_cli_env
