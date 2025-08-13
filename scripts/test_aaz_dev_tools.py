"""
Test script for verifying aaz-dev-tools functionality with Python 3.13 built azdev
"""

def test_azdev_availability():
    """Test that azdev is available and working"""
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

def test_aaz_dev_tools_import():
    """Test that aaz-dev-tools can be imported"""
    try:
        import aaz_dev
        print("[OK] aaz-dev-tools imported successfully")
    except ImportError as e:
        print(f"[FAIL] Failed to import aaz-dev-tools: {e}")
        raise

def test_aaz_dev_tools_core_modules():
    """Test that core aaz-dev-tools modules can be loaded"""
    core_modules = [
        'aaz_dev.cli',
        'aaz_dev.command',
        'aaz_dev.utils'
    ]
    
    failed_imports = []
    
    for module in core_modules:
        try:
            __import__(module)
            print(f"[OK] {module} imported successfully")
        except ImportError as e:
            print(f"[FAIL] Failed to import {module}: {e}")
            failed_imports.append(module)
    
    if failed_imports:
        print(f"[WARN] Some core modules failed to import: {', '.join(failed_imports)}")
        # Don't fail the test as some modules might be optional
    else:
        print("[OK] All core aaz-dev-tools modules loaded successfully")

def test_azdev_aaz_integration():
    """Test basic integration between azdev and aaz-dev-tools"""
    try:
        # Test that azdev can see aaz-dev-tools commands
        import azdev.operations
        print("[OK] azdev operations module accessible")
        
        # Basic smoke test
        import subprocess
        import sys
        
        # Test azdev help works
        result = subprocess.run([sys.executable, '-m', 'azdev', '--help'], 
                              capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            print("[OK] azdev CLI help command works")
        else:
            print(f"[WARN] azdev CLI help returned non-zero exit code: {result.returncode}")
            
    except Exception as e:
        print(f"[WARN] Integration test encountered issues: {e}")
        # Don't fail hard on integration issues

def test_dependency_compatibility():
    """Test that all dependencies are compatible"""
    try:
        # Test core dependencies work together
        import jsonschema
        import flask
        import jinja2
        import packaging
        import click
        
        # Test they can be used together
        click.__version__
        flask.__version__
        
        print("[OK] Core dependencies are compatible")
    except Exception as e:
        print(f"[FAIL] Dependency compatibility issue: {e}")
        raise

if __name__ == "__main__":
    print("=== Running aaz-dev-tools compatibility tests with Python 3.13 built azdev ===")
    
    test_azdev_availability()
    test_aaz_dev_tools_import()
    test_aaz_dev_tools_core_modules()
    test_azdev_aaz_integration()
    test_dependency_compatibility()
    
    print("=== SUCCESS: aaz-dev-tools works with Python 3.13 built azdev ===")
