#!/usr/bin/env python3
"""
检查代码与 Python 版本的兼容性
"""
import sys
import os

def check_python_version():
    """检查 Python 版本"""
    version = sys.version_info
    print(f"Python 版本: {version.major}.{version.minor}.{version.micro}")
    
    # 检查最低版本要求
    if version.major < 3:
        print("✗ 需要 Python 3.x")
        return False
    if version.major == 3 and version.minor < 7:
        print("⚠ 建议使用 Python 3.7+ (当前版本可能缺少某些特性)")
        return True
    if version.major == 3 and version.minor >= 7:
        print("✓ Python 版本符合要求")
        return True
    
    return True

def check_features():
    """检查 Python 特性支持"""
    issues = []
    
    # 检查 fromisoformat (Python 3.7+)
    from datetime import datetime
    if not hasattr(datetime, 'fromisoformat'):
        issues.append("datetime.fromisoformat() 需要 Python 3.7+")
    else:
        print("✓ 支持 datetime.fromisoformat()")
    
    # 检查类型提示 (Python 3.5+)
    try:
        from typing import List, Dict, Optional, Union
        print("✓ 支持 typing 模块")
    except ImportError:
        issues.append("typing 模块不可用")
    
    # 检查 f-string (Python 3.6+)
    test_fstring = f"test {1+1}"
    if test_fstring == "test 2":
        print("✓ 支持 f-string")
    else:
        issues.append("不支持 f-string (需要 Python 3.6+)")
    
    # 检查类型注解语法 (Python 3.9+)
    if sys.version_info >= (3, 9):
        print("✓ 支持 list[], dict[] 类型注解语法")
    else:
        print("⚠ 不支持 list[], dict[] 语法，需要使用 List[], Dict[]")
    
    if issues:
        print("\n⚠ 发现兼容性问题:")
        for issue in issues:
            print(f"  - {issue}")
        return False
    
    return True

def check_imports():
    """检查关键模块导入"""
    print("\n>>> 检查模块导入...")
    
    backend_path = os.path.join(os.path.dirname(__file__), '..', 'backend')
    if os.path.exists(backend_path):
        sys.path.insert(0, backend_path)
    
    modules = [
        ('database', 'SessionLocal'),
        ('models', 'Article'),
        ('models', 'User'),
        ('models', 'auth', 'get_password_hash'),
        ('schemas', 'ArticleResponse'),
    ]
    
    failed = []
    for module_info in modules:
        try:
            if len(module_info) == 2:
                module_name, attr_name = module_info
                module = __import__(module_name, fromlist=[attr_name])
                getattr(module, attr_name)
                print(f"✓ {module_name}.{attr_name}")
            else:
                module_name, submodule, attr_name = module_info
                module = __import__(module_name, fromlist=[submodule])
                sub = getattr(module, submodule)
                getattr(sub, attr_name)
                print(f"✓ {module_name}.{submodule}.{attr_name}")
        except Exception as e:
            print(f"✗ {'.'.join(module_info)}: {e}")
            failed.append(module_info)
    
    if failed:
        print(f"\n✗ {len(failed)} 个模块导入失败")
        return False
    
    print("\n✓ 所有模块导入成功")
    return True

def main():
    print("=" * 50)
    print("Python 兼容性检查")
    print("=" * 50)
    print()
    
    # 检查版本
    version_ok = check_python_version()
    print()
    
    # 检查特性
    features_ok = check_features()
    print()
    
    # 检查导入
    imports_ok = check_imports()
    print()
    
    # 总结
    print("=" * 50)
    if version_ok and features_ok and imports_ok:
        print("✓ 兼容性检查通过")
        return 0
    else:
        print("✗ 发现兼容性问题，请修复后重试")
        return 1

if __name__ == "__main__":
    sys.exit(main())

