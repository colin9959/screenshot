#!/bin/bash
set -e

# ===================== 配置 =====================
BDINFO_URL_X64="https://github.com/dotnetcorecorner/BDInfo/releases/download/linux-2.0.6/bdinfo_linux_v2.0.6.zip"
BDINFO_URL_ARM64="https://github.com/colin9959/BDInfo/releases/download/1.0.0/bdinfo_linux_arm64_v2.0.6.zip"
INSTALL_DIR="/usr/local/bin"
OUTPUT_DIR="/home/screenshot"
MOUNT_POINT="/mnt/iso"
TEMPDIR="/tmp/bdinfo_$$"

mkdir -p "$OUTPUT_DIR" "$MOUNT_POINT" "$TEMPDIR"

# ===================== 安装 BDInfo =====================
install_bdinfo() {
    if command -v BDInfo &>/dev/null; then return; fi
    arch=$(uname -m)
    if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        echo "检测到 ARM64 架构，安装 BDInfo..."
        url="$BDINFO_URL_ARM64"
    else
        echo "检测到 x86_64 架构，安装 BDInfo..."
        url="$BDINFO_URL_X64"
    fi
    wget -q -O "$TEMPDIR/bd.zip" "$url" || wget -q -O "$TEMPDIR/bd.zip" "https://ghfast.top/$url"
    unzip -q -o "$TEMPDIR/bd.zip" -d "$TEMPDIR"
    chmod +x "$TEMPDIR"/BDInfo*
    sudo cp "$TEMPDIR"/BDInfo* "$INSTALL_DIR/"
    echo "BDInfo 安装成功！"
}

# ===================== 显示所有 m2ts =====================
show_m2ts() {
    local path="$1"
    echo -e "\n==================== 所有 m2ts 文件（从大到小）===================="
    find "$path" -type f -iname "*.m2ts" | xargs du -b | sort -nr | awk '{printf "%d\t%s\n", $1, substr($0, index($0,$2))}' | while read -r size file; do
        ((i++))
        echo -e "[$i]\t$(numfmt --to=iec $size)\t$file"
        echo "$file" >> "$TEMPDIR/list.txt"
    done
    echo "======================================================================"
}

# ===================== 选择文件 =====================
choose_files() {
    mapfile -t all_files < "$TEMPDIR/list.txt"
    read -p "输入要扫描的序号（多选用空格分隔，输入 q 开始）：" input
    if [[ "$input" == "q" ]]; then exit 0; fi
    selected=()
    for idx in $input; do
        if [[ $idx =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#all_files[@]} )); then
            selected+=("${all_files[$idx-1]}")
        fi
    done
}

# ===================== 扫描 =====================
scan() {
    for file in "$@"; do
        echo -e "\n正在扫描：$file"
        name=$(basename "$file" .m2ts)
        BDInfo -p "$file" -o "$TEMPDIR/$name.txt"
        cp "$TEMPDIR/$name.txt" "$OUTPUT_DIR/bdinfo_$name.txt"
        echo "✅ 扫描完成，保存到：$OUTPUT_DIR/bdinfo_$name.txt"
    done
}

# ===================== 清理 =====================
cleanup() {
    mountpoint -q "$MOUNT_POINT" && sudo umount "$MOUNT_POINT" 2>/dev/null
    rm -rf "$TEMPDIR"
}
trap cleanup EXIT

# ===================== 主程序 =====================
[[ $# -ne 1 ]] && { echo "用法：$0 <蓝光目录/ISO>"; exit 1; }
input="$1"
install_bdinfo

if [[ "${input##*.}" == "iso" ]]; then
    echo "挂载 ISO..."
    sudo mount -o loop "$input" "$MOUNT_POINT"
    target="$MOUNT_POINT"
else
    target="$input"
fi

# 显示列表
show_m2ts "$target"

# 选择
choose_files

# 扫描
scan "${selected[@]}"

echo -e "\n🎉 全部扫描完成！"
