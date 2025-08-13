"""
Test script for verifying azdev compatibility with aaz-dev-tools dependencies
"""

def test_azdev_import():
    """Test that azdev can be imported and basic info accessed"""
    try:
        import azdev
        print(f"[OK] azdev version: {azdev.__VERSION__}")
        print("[OK] azdev imported successfully")
    except ImportError as e:
        print(f"[FAIL] Failed to import azdev: {e}")
        raise
    except AttributeError as e:
        print(f"[FAIL] azdev imported but version not accessible: {e}")
        raise

def test_azdev_core_modules():
    """Test that core azdev modules can be loaded"""
    try:
        import azdev.utilities
        import azdev.operations
        print("[OK] Core azdev modules loaded successfully")
    except ImportError as e:
        print(f"[FAIL] Failed to import core azdev modules: {e}")
        raise

def test_aaz_dev_tools_dependencies():
    """Test that aaz-dev-tools dependencies are compatible"""
    dependencies = [
        'schematics',
        'yaml',  # pyyaml
        'fuzzywuzzy',
        'pluralizer', 
        'lxml',
        'flask',
        'cachelib',
        'xmltodict',
        'packaging',
        'jinja2',
        'jsonschema',
        'click',
        'setuptools',
        'azure.mgmt.core'  # azure-mgmt-core
    ]
    
    failed_imports = []
    
    for dep in dependencies:
        try:
            if dep == 'yaml':
                import yaml
            elif dep == 'azure.mgmt.core':
                import azure.mgmt.core
            else:
                __import__(dep)
            print(f"[OK] {dep} imported successfully")
        except ImportError as e:
            print(f"[FAIL] Failed to import {dep}: {e}")
            failed_imports.append(dep)
    
    if failed_imports:
        raise ImportError(f"Failed to import dependencies: {', '.join(failed_imports)}")
    
    print("[OK] All aaz-dev-tools dependencies imported successfully")

def test_no_version_conflicts():
    """Basic test to ensure no obvious version conflicts"""
    try:
        # Test some common conflict scenarios
        import packaging.version
        import setuptools
        import click
        
        # Try to access version info to ensure packages are properly installed
        click.__version__
        setuptools.__version__
        
        print("[OK] No obvious version conflicts detected")
    except Exception as e:
        print(f"[FAIL] Potential version conflict detected: {e}")
        raise

if __name__ == "__main__":
    print("=== Running azdev compatibility tests ===")
    
    test_azdev_import()
    test_azdev_core_modules() 
    test_aaz_dev_tools_dependencies()
    test_no_version_conflicts()
    
    print("=== SUCCESS: All compatibility tests passed ===")
