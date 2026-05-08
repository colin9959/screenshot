#!/bin/bash
set -e

echo "========================================"
echo "      开始执行批量安装与配置脚本"
echo "        支持：ss截图 + BDInfo蓝光检测"
echo "========================================"

# 1. 创建ISO挂载目录
echo -e "\n[1/5] 创建ISO挂载目录 /mnt/iso..."
sudo mkdir -p /mnt/iso 2>/dev/null || true

# 2. 下载 ss.sh
echo -e "\n[2/5] 下载 ss.sh..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/ss.sh -o /usr/local/bin/ss.sh
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/nconvert -o /usr/local/bin/nconvert

# 3. 授权
echo -e "\n[3/5] 赋予执行权限..."
sudo chmod +x /usr/local/bin/ss.sh
sudo chmod +x /usr/local/bin/nconvert

# 4. 安装 BDInfo （修复路径 + 修复换行符）
echo -e "\n[4/5] 安装 BDInfoCLI..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/bd.sh -o /usr/local/bin/bd.sh
sudo chmod +x /usr/local/bin/bd.sh

# 5. 完成
echo -e "\n========================================"
echo "           安装完成！"
echo ""
echo " ✅ ss.sh    截图工具"
echo " ✅ nconvert 图片压缩"
echo " ✅ bd.sh    蓝光检测"
echo "========================================"
