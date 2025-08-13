#!/usr/bin/env python3
"""
Universal import testing script for Python package compatibility.
Tests imports based on requirements file and package type detection.
"""

import sys
import importlib
import argparse
import re
from pathlib import Path


def parse_requirements(requirements_file):
    """Parse requirements file and extract package names."""
    packages = []
    
    if not Path(requirements_file).exists():
        print(f"[FAIL] Requirements file not found: {requirements_file}")
        return packages
    
    with open(requirements_file, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip empty lines and comments
            if not line or line.startswith('#'):
                continue
            
            # Extract package name (everything before version specifiers)
            # Handle cases like: package>=1.0, package==1.0, package[extra]>=1.0
            match = re.match(r'^([a-zA-Z0-9_.-]+)', line)
            if match:
                package_name = match.group(1)
                # Convert underscores to hyphens for package names
                package_name = package_name.replace('_', '-')
                packages.append(package_name)
    
    return packages


def detect_package_type(requirements_file):
    """Detect whether this is aaz-dev-tools or azure-cli based on requirements."""
    packages = parse_requirements(requirements_file)
    
    # Check for distinctive packages
    aaz_indicators = ['swagger-to-sdk', 'pyyaml', 'jinja2']
    cli_indicators = ['azure-cli-core', 'azure-mgmt-resource', 'knack', 'msrestazure']
    
    aaz_count = sum(1 for pkg in packages if any(indicator in pkg.lower() for indicator in aaz_indicators))
    cli_count = sum(1 for pkg in packages if any(indicator in pkg.lower() for indicator in cli_indicators))
    
    if cli_count > aaz_count:
        return 'azure-cli'
    else:
        return 'aaz-dev-tools'


def get_test_modules(package_type):
    """Get list of modules to test based on package type."""
    
    if package_type == 'azure-cli':
        return [
            'azure.cli.core',
            'azure.cli.command_modules',
            'azure.mgmt.resource',
            'azure.mgmt.storage', 
            'azure.mgmt.compute',
            'azure.mgmt.network',
            'azure.identity',
            'azure.storage.blob',
            'azure.keyvault.secrets',
            'msrestazure',
            'knack'
        ]
    else:  # aaz-dev-tools
        return [
            'swagger_to_sdk',
            'yaml',
            'jinja2',
            'jsonschema',
            'requests',
            'click',
            'packaging',
            'setuptools',
            'wheel'
        ]


def test_basic_functionality(package_type):
    """Test basic functionality based on package type."""
    
    try:
        if package_type == 'azure-cli':
            from azure.cli.core import get_default_cli
            cli = get_default_cli()
            print('[OK] Azure CLI core functionality accessible')
            return True
        else:  # aaz-dev-tools
            # Test some basic aaz-dev-tools functionality
            import yaml
            import jinja2
            
            # Test YAML processing
            test_data = {'test': 'value'}
            yaml_str = yaml.dump(test_data)
            parsed = yaml.safe_load(yaml_str)
            assert parsed == test_data
            
            # Test Jinja2 templating
            template = jinja2.Template('Hello {{ name }}!')
            result = template.render(name='World')
            assert result == 'Hello World!'
            
            print('[OK] AAZ dev tools core functionality accessible')
            return True
            
    except Exception as e:
        print(f'[WARN] Basic functionality test failed: {e}')
        return False


def test_imports(requirements_file, python_version, os_name):
    """Test imports for packages in requirements file."""
    
    print(f"Testing imports from {requirements_file} on {os_name} with Python {python_version}")
    print("=" * 60)
    
    # Detect package type
    package_type = detect_package_type(requirements_file)
    print(f"Detected package type: {package_type}")
    
    # Get modules to test
    modules_to_test = get_test_modules(package_type)
    
    failed_imports = []
    successful_imports = []
    
    print(f"\nTesting {len(modules_to_test)} key modules...")
    
    for module in modules_to_test:
        try:
            importlib.import_module(module)
            successful_imports.append(module)
            print(f'[OK] {module}')
        except ImportError as e:
            failed_imports.append((module, str(e)))
            print(f'[FAIL] {module}: {e}')
        except Exception as e:
            failed_imports.append((module, str(e)))
            print(f'[ERROR] {module}: {e}')
    
    print(f'\nSummary for Python {sys.version}:')
    print(f'  Package type: {package_type}')
    print(f'  Successful imports: {len(successful_imports)}')
    print(f'  Failed imports: {len(failed_imports)}')
    
    if failed_imports:
        print('\nFailed imports:')
        for module, error in failed_imports:
            print(f'  - {module}: {error}')
    
    # Test basic functionality
    print('\nTesting basic functionality...')
    functionality_ok = test_basic_functionality(package_type)
    
    # Final result
    if failed_imports:
        print(f'\n[FAIL] {len(failed_imports)} module(s) failed to import')
        return False
    else:
        print(f'\n[OK] All {package_type} module imports successful')
        return True


def main():
    parser = argparse.ArgumentParser(description='Test Python package imports from requirements file')
    parser.add_argument('requirements_file', help='Path to requirements file')
    parser.add_argument('python_version', help='Python version being tested')
    parser.add_argument('os_name', help='Operating system name')
    
    args = parser.parse_args()
    
    success = test_imports(args.requirements_file, args.python_version, args.os_name)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
