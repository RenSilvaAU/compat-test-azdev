#!/usr/bin/env python3
"""
Universal import testing script for Python package compatibility.
Tests imports based on packages listed in requirements file.
"""

import sys
import importlib
import argparse
import re
from pathlib import Path


def parse_requirements(requirements_file):
    """Parse requirements file and extract package names with their import names."""
    packages = []
    
    if not Path(requirements_file).exists():
        print(f"[FAIL] Requirements file not found: {requirements_file}")
        return packages
    
    with open(requirements_file, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip empty lines, comments, and git/url requirements
            if not line or line.startswith('#') or line.startswith('git+') or line.startswith('http'):
                continue
            
            # Skip editable installs and other special formats
            if line.startswith('-e') or line.startswith('--'):
                continue
            
            # Extract package name (everything before version specifiers, extras, etc.)
            # Handle cases like: package>=1.0, package==1.0, package[extra]>=1.0, package @ url
            match = re.match(r'^([a-zA-Z0-9_.-]+)', line.split()[0])
            if match:
                package_name = match.group(1)
                packages.append(package_name)
    
    return packages


def get_import_name(package_name):
    """Convert package name to likely import name."""
    # Common package name to import name mappings
    name_mappings = {
        'pyyaml': 'yaml',
        'pillow': 'PIL',
        'beautifulsoup4': 'bs4',
        'python-dateutil': 'dateutil',
        'msgpack-python': 'msgpack',
        'pycrypto': 'Crypto',
        'pycryptodome': 'Crypto',
        'python-levenshtein': 'Levenshtein',
        'azure-cli-core': 'azure.cli.core',
        'azure-mgmt-core': 'azure.mgmt.core',
        'azure-mgmt-resource': 'azure.mgmt.resource',
        'azure-mgmt-storage': 'azure.mgmt.storage',
        'azure-mgmt-compute': 'azure.mgmt.compute',
        'azure-mgmt-network': 'azure.mgmt.network',
        'azure-storage-blob': 'azure.storage.blob',
        'azure-keyvault-secrets': 'azure.keyvault.secrets',
        'azure-identity': 'azure.identity',
        'azure-common': 'azure.common',
        'azure-core': 'azure.core',
        'msrestazure': 'msrestazure',
        'msrest': 'msrest',
        'azure-cli-command-modules': 'azure.cli.command_modules',
        'swagger-to-sdk': 'swagger_to_sdk',
        'jinja2': 'jinja2',
        'markupsafe': 'markupsafe',
        'jsonschema': 'jsonschema',
        'fuzzywuzzy': 'fuzzywuzzy',
        'pluralizer': 'pluralizer',
        'xmltodict': 'xmltodict',
        'cachelib': 'cachelib',
    }
    
    # Check if we have a specific mapping
    package_lower = package_name.lower()
    if package_lower in name_mappings:
        return name_mappings[package_lower]
    
    # For azure packages, try to construct the import path
    if package_name.startswith('azure-'):
        parts = package_name.split('-')
        if len(parts) >= 2:
            return 'azure.' + '.'.join(parts[1:])
    
    # Default: replace hyphens with underscores
    return package_name.replace('-', '_')


def test_package_import(package_name, import_name):
    """Test importing a single package."""
    try:
        importlib.import_module(import_name)
        return True, None
    except ImportError as e:
        return False, str(e)
    except Exception as e:
        return False, f"Unexpected error: {str(e)}"


def test_basic_functionality(packages):
    """Test basic functionality of commonly used packages."""
    functionality_tests = []
    
    # Test YAML if available
    if any('yaml' in pkg.lower() for pkg in packages):
        try:
            import yaml
            test_data = {'test': 'value'}
            yaml_str = yaml.dump(test_data)
            parsed = yaml.safe_load(yaml_str)
            assert parsed == test_data
            functionality_tests.append(('YAML processing', True, None))
        except Exception as e:
            functionality_tests.append(('YAML processing', False, str(e)))
    
    # Test Jinja2 if available
    if any('jinja2' in pkg.lower() for pkg in packages):
        try:
            import jinja2
            template = jinja2.Template('Hello {{ name }}!')
            result = template.render(name='World')
            assert result == 'Hello World!'
            functionality_tests.append(('Jinja2 templating', True, None))
        except Exception as e:
            functionality_tests.append(('Jinja2 templating', False, str(e)))
    
    # Test Azure CLI core if available
    if any('azure-cli-core' in pkg.lower() for pkg in packages):
        try:
            from azure.cli.core import get_default_cli
            cli = get_default_cli()
            functionality_tests.append(('Azure CLI core', True, None))
        except Exception as e:
            functionality_tests.append(('Azure CLI core', False, str(e)))
    
    # Test JSON schema if available
    if any('jsonschema' in pkg.lower() for pkg in packages):
        try:
            import jsonschema
            schema = {"type": "object", "properties": {"name": {"type": "string"}}}
            jsonschema.validate({"name": "test"}, schema)
            functionality_tests.append(('JSON Schema validation', True, None))
        except Exception as e:
            functionality_tests.append(('JSON Schema validation', False, str(e)))
    
    return functionality_tests


def test_imports(requirements_file, python_version, os_name):
    """Test imports for packages in requirements file."""
    
    print(f"Testing imports from {requirements_file} on {os_name} with Python {python_version}")
    print("=" * 60)
    
    # Parse requirements file
    packages = parse_requirements(requirements_file)
    if not packages:
        print("[FAIL] No packages found in requirements file")
        return False
    
    print(f"Found {len(packages)} packages to test:")
    for pkg in packages:
        print(f"  - {pkg}")
    print()
    
    failed_imports = []
    successful_imports = []
    skipped_imports = []
    
    print("Testing package imports...")
    
    for package_name in packages:
        # Skip packages that are typically not importable directly
        skip_packages = ['azdev', 'setuptools', 'pip', 'wheel', 'build']
        if package_name.lower() in skip_packages:
            skipped_imports.append(package_name)
            print(f'[SKIP] {package_name} (build/dev tool)')
            continue
        
        import_name = get_import_name(package_name)
        success, error = test_package_import(package_name, import_name)
        
        if success:
            successful_imports.append((package_name, import_name))
            print(f'[OK] {package_name} -> {import_name}')
        else:
            failed_imports.append((package_name, import_name, error))
            print(f'[FAIL] {package_name} -> {import_name}: {error}')
    
    print(f'\nSummary for Python {sys.version}:')
    print(f'  Total packages: {len(packages)}')
    print(f'  Successful imports: {len(successful_imports)}')
    print(f'  Failed imports: {len(failed_imports)}')
    print(f'  Skipped imports: {len(skipped_imports)}')
    
    if failed_imports:
        print('\nFailed imports:')
        for package_name, import_name, error in failed_imports:
            print(f'  - {package_name} ({import_name}): {error}')
    
    if skipped_imports:
        print('\nSkipped packages:')
        for package_name in skipped_imports:
            print(f'  - {package_name}')
    
    # Test basic functionality
    print('\nTesting basic functionality...')
    functionality_tests = test_basic_functionality(packages)
    
    for test_name, success, error in functionality_tests:
        if success:
            print(f'[OK] {test_name}')
        else:
            print(f'[FAIL] {test_name}: {error}')
    
    # Final result
    total_failures = len(failed_imports) + len([t for t in functionality_tests if not t[1]])
    
    if total_failures == 0:
        print(f'\n[OK] All package imports and functionality tests successful')
        return True
    else:
        print(f'\n[FAIL] {total_failures} test(s) failed')
        return False


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
