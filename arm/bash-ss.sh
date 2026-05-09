#!/bin/bash
set -e
#
echo "========================================"
echo "      开始执行批量安装与配置脚本-arm版本"
echo "        支持：ss截图 + BDInfo蓝光检测"
echo "========================================"
#
# 1. 创建ISO挂载目录
echo -e "\n[1/5] 创建ISO挂载目录 /mnt/iso..."
sudo mkdir -p /mnt/iso
# 2. 下载 ss.sh 和 bd.sh
echo -e "\n[2/5] 下载 ss.sh和bd.sh文件..."
# 先删除旧版本（如果存在）
chmod -x /usr/local/bin/ss.sh
chmod -x /usr/local/bin/bd.sh
chmod -x /usr/local/bin/BDInfo
sudo rm -f /usr/local/bin/ss.sh
sudo rm -f /usr/local/bin/bd.sh
sudo rm -f /usr/local/bin/BDInfo
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/arm/ss.sh -o /usr/local/bin/ss.sh
# 3. 赋予执行权限
echo -e "\n[3/5] 赋予文件执行权限..."
sudo chmod +x /usr/local/bin/ss.sh
# 4. 下载 bd.sh文件（arm版）
echo -e "\n[4/5] 下载并安装 BDInfo..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/arm/bd.sh -o /usr/local/bin/bd.sh
sudo chmod +x /usr/local/bin/bd.sh
# ===================== 固定配置 =====================
BDINFO_URL_X64="https://github.com/dotnetcorecorner/BDInfo/releases/download/linux-2.0.6/bdinfo_linux_v2.0.6.zip"
BDINFO_URL_ARM64="https://github.com/colin9959/BDInfo/releases/download/1.0.0/bdinfo_linux_arm64_v2.0.6.zip"
INSTALL_DIR="/usr/local/bin"

# 三个必须的目录（已补全）
OUTPUT_DIR="/home/screenshot"
MOUNT_POINT="/mnt/iso"
TEMPDIR="/tmp/bdinfo_temp_$$"

# 创建目录
mkdir -p "$OUTPUT_DIR"
mkdir -p "$MOUNT_POINT"
mkdir -p "$TEMPDIR"

# ===================== 自动安装依赖（已安装则跳过） =====================
install_deps() {
    local need_install=()

    # 检测依赖是否已安装
    if ! command -v wget &>/dev/null; then
        need_install+=("wget")
    fi
    if ! command -v unzip &>/dev/null; then
        need_install+=("unzip")
    fi

    # 检测 libicu 是否安装
    local has_libicu=1
    if command -v apt &>/dev/null; then
        dpkg -l | grep -q libicu-dev || has_libicu=0
    elif command -v dnf &>/dev/null || command -v yum &>/dev/null; then
        rpm -q libicu &>/dev/null || has_libicu=0
    fi

    # libicu 未安装，加入安装列表
    if [ $has_libicu -eq 0 ]; then
        if command -v apt &>/dev/null; then
            need_install+=("libicu-dev")
        else
            need_install+=("libicu")
        fi
    fi

    # 无需要安装的依赖，直接退出
    if [ ${#need_install[@]} -eq 0 ]; then
        echo "所有依赖项已安装，跳过安装" >&2
        return
    fi

    echo "正在安装缺失依赖：${need_install[*]}" >&2
    if command -v apt &>/dev/null; then
        sudo apt update -qq
        sudo apt install -y "${need_install[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${need_install[@]}"
    elif command -v yum &>/dev/null; then
        sudo yum install -y "${need_install[@]}"
    fi
}

# 先安装依赖
install_deps

# 强制设置 .NET 全局化模式（彻底修复ICU错误）
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

# ===================== 安装 BDInfo（已安装则跳过） =====================
install_bdinfo() {
    # 检测 BDInfo 是否已安装，有则直接跳过
    if command -v BDInfo &>/dev/null; then
        echo "BDInfo 已安装，跳过下载安装" >&2
        return 0
    fi

    echo "未检测到 BDInfo，开始自动安装..." >&2
    local arch=$(uname -m)
    local bdinfo_url=""
    
    if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        echo "检测到 ARM64 架构" >&2
        bdinfo_url="$BDINFO_URL_ARM64"
    else
        echo "检测到 x86_64 架构" >&2
        bdinfo_url="$BDINFO_URL_X64"
    fi
    
    local mirrors=(
        "$bdinfo_url"
        "https://ghfast.top/$bdinfo_url"
    )
    
    for mirror in "${mirrors[@]}"; do
        if wget -q "$mirror" -O "$TEMPDIR/bdinfo.zip"; then
            unzip -q -o "$TEMPDIR/bdinfo.zip" -d "$TEMPDIR"
            chmod +x "$TEMPDIR"/BDInfo*
            sudo cp "$TEMPDIR"/BDInfo* "$INSTALL_DIR/"
            echo "BDInfo 安装成功！" >&2
            rm -rf "$TEMPDIR"
            mkdir -p "$TEMPDIR"
            return 0
        fi
    done
    echo "错误：无法下载 BDInfo" >&2
    exit 1
}

install_bdinfo

# 5. 安装完成提示
echo -e "\n========================================"
echo "           所有操作执行完成！"
echo ""
echo " ✅ screenshot   全局命令：ss.sh"
echo " ✅ bdinfo       全局命令：bd.sh"
echo ""
echo " 三个工具已全部安装成功！"
echo "========================================"
