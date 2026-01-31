#!/bin/bash
# 在服务器上直接修复兼容性检查脚本
# 使用方法: 在服务器上执行: bash deploy/fix-compatibility-check-on-server.sh
# 或者直接复制下面的命令到服务器执行

cd /var/www/my-fullstack-app/deploy

# 备份原文件
if [ -f "检查Python兼容性.py" ]; then
    cp 检查Python兼容性.py 检查Python兼容性.py.backup.$(date +%Y%m%d_%H%M%S)
    echo "✓ 已备份原文件"
fi

# 修复导入错误：将 models.auth 改为从 auth 模块导入
cat > 检查Python兼容性.py << 'PYTHON_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Python 兼容性检查脚本
检查当前 Python 版本是否满足项目要求
"""

import sys
import os

# 添加项目路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

print("=" * 50)
print("Python 兼容性检查")
print("=" * 50)
print()

# 1. 检查 Python 版本
print(">>> Python 版本检查...")
python_version = sys.version_info
print(f"Python 版本: {python_version.major}.{python_version.minor}.{python_version.micro}")

if python_version.major < 3 or (python_version.major == 3 and python_version.minor < 8):
    print("✗ Python 版本过低，需要 Python 3.8+")
    sys.exit(1)
else:
    print("√ Python 版本符合要求")
print()

# 2. 检查关键特性
print(">>> 检查关键特性支持...")
issues = []

# 检查 datetime.fromisoformat (Python 3.7+)
try:
    from datetime import datetime
    datetime.fromisoformat("2023-01-01T00:00:00")
    print("√ 支持 datetime.fromisoformat()")
except (AttributeError, ValueError):
    print("✗ 不支持 datetime.fromisoformat()")
    issues.append("datetime.fromisoformat()")

# 检查 typing 模块
try:
    import typing
    print("√ 支持 typing 模块")
except ImportError:
    print("✗ 不支持 typing 模块")
    issues.append("typing 模块")

# 检查 f-string (Python 3.6+)
try:
    test_var = "test"
    f"测试: {test_var}"
    print("√ 支持 f-string")
except:
    print("✗ 不支持 f-string")
    issues.append("f-string")

# 检查类型注解语法 (Python 3.9+)
try:
    from typing import List, Dict
    def test_func() -> List[Dict[str, str]]:
        return []
    # Python 3.9+ 支持 list[], dict[] 语法
    if python_version.minor >= 9:
        def test_func2() -> list[dict[str, str]]:
            return []
        print("√ 支持 list[], dict[] 类型注解语法")
    else:
        print("√ 支持类型注解（使用 List[], Dict[] 语法）")
except:
    print("✗ 类型注解支持有问题")
    issues.append("类型注解")

print()

# 3. 检查模块导入
print(">>> 检查模块导入...")
import_issues = []

try:
    from database import SessionLocal
    print("✓ database.SessionLocal")
except Exception as e:
    print(f"✗ database.SessionLocal: {e}")
    import_issues.append(f"database: {e}")

try:
    from models import Article
    print("✓ models.Article")
except Exception as e:
    print(f"✗ models.Article: {e}")
    import_issues.append(f"models.Article: {e}")

try:
    from models import User
    print("✓ models.User")
except Exception as e:
    print(f"✗ models.User: {e}")
    import_issues.append(f"models.User: {e}")

try:
    # 修复：从 auth 模块导入，而不是 models.auth
    from auth import get_password_hash, verify_password
    print("✓ auth.get_password_hash")
    print("✓ auth.verify_password")
except Exception as e:
    print(f"✗ auth.get_password_hash: {e}")
    import_issues.append(f"auth: {e}")

try:
    from schemas import ArticleResponse
    print("✓ schemas.ArticleResponse")
except Exception as e:
    print(f"✗ schemas.ArticleResponse: {e}")
    import_issues.append(f"schemas.ArticleResponse: {e}")

print()

# 4. 总结
if issues:
    print(f"✗ 发现 {len(issues)} 个特性不支持: {', '.join(issues)}")
else:
    print("√ 所有特性检查通过")

if import_issues:
    print(f"✗ {len(import_issues)} 个模块导入失败")
    for issue in import_issues:
        print(f"  - {issue}")
else:
    print("√ 所有模块导入成功")

print()

# 5. 最终结果
if issues or import_issues:
    print("✗ 发现兼容性问题, 请修复后重试")
    sys.exit(1)
else:
    print("=" * 50)
    print("√ 兼容性检查通过！")
    print("=" * 50)
    sys.exit(0)
PYTHON_EOF

chmod +x 检查Python兼容性.py

echo ""
echo "✓ 修复完成！"
echo ""
echo "现在可以运行检查："
echo "  python3 deploy/检查Python兼容性.py"

