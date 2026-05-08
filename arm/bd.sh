#!/bin/bash
set -eo pipefail

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

    mirrors=("$url" "https://ghfast.top/$url")
    for m in "${mirrors[@]}"; do
        if wget -q "$m" -O "$TEMPDIR/bd.zip"; then
            unzip -q -o "$TEMPDIR/bd.zip" -d "$TEMPDIR"
            chmod +x "$TEMPDIR"/BDInfo*
            sudo cp "$TEMPDIR"/BDInfo* "$INSTALL_DIR/"
            echo "BDInfo 安装成功！"
            break
        fi
    done
}

# ===================== 核心：获取 m2ts 列表（纯数据，无界面） =====================
get_m2ts_list() {
    find "$1" -type f -iname "*.m2ts" | while read -r f; do
        size=$(stat -c%s "$f")
        echo "$size"$'\t'"$f"
    done | sort -nr | cut -f2
}

# ===================== 交互选择（安全、干净、无脏数据） =====================
show_menu() {
    local files=("$@")
    echo -e "\n========== 所有 m2ts 文件（从大到小）=========="
    for i in "${!files[@]}"; do
        size=$(du -h "${files[$i]}" | awk '{print $1}')
        echo "[$((i+1))]  $size  ${files[$i]}"
    done
    echo -e "\n输入序号多选（空格分隔），输入 q 开始扫描"
    read -p "请选择：" ans
    echo "$ans"
}

# ===================== 扫描单个 =====================
scan_file() {
    local f="$1"
    local name=$(basename "$f" .m2ts)
    local out="$TEMPDIR/$name.txt"

    echo -e "\n====================================="
    echo "正在扫描：$f"
    echo "====================================="

    if BDInfo -p "$f" -o "$out" &>/dev/null; then
        cp "$out" "$OUTPUT_DIR/bdinfo_$name.txt"
        awk '
        BEGIN{RS="DISC INFO:";max=0;res=""}
        NR>1{
            t=$0; sub(/FILES:.*/,"",t)
            if(match(t,/Size:[ ]*([0-9,]+)/)) {
                v=gensub(/,/,"","g",substr(t,RSTART+5))
                if(v+0>max){max=v;res=t}
            }
        }
        END{
            if(res){
                sub(/ +$/,"",res)
                print "--- BDInfo 信息 ---"
                print res
                print "-------------------"
            }
        }' "$out"
    else
        echo "⚠️  扫描失败"
    fi
    rm -f "$out"
}

# ===================== 清理 =====================
cleanup() {
    mountpoint -q "$MOUNT_POINT" && sudo umount "$MOUNT_POINT" 2>/dev/null
    rm -rf "$TEMPDIR"
}
trap cleanup EXIT

# ===================== 主程序 =====================
[[ $# -ne 1 ]] && { echo "用法：$0 <蓝光目录/ISO文件>"; exit 1; }
input="$1"
install_bdinfo

# 挂载ISO
if [[ "${input##*.}" == "iso" ]]; then
    echo "挂载 ISO..."
    sudo mount -o loop "$input" "$MOUNT_POINT"
    target="$MOUNT_POINT"
else
    target="$input"
fi

# 读取文件列表（纯路径）
mapfile -t all_files < <(get_m2ts_list "$target")
[[ ${#all_files[@]} -eq 0 ]] && { echo "未找到 m2ts"; exit 1; }

# 选择
ans=$(show_menu "${all_files[@]}")
[[ "$ans" == "q" ]] && exit 0

# 解析选择
selected=()
for n in $ans; do
    if [[ $n =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#all_files[@]} )); then
        selected+=("${all_files[$n-1]}")
    fi
done

# 批量扫描
for f in "${selected[@]}"; do
    scan_file "$f"
done

echo -e "\n✅ 扫描完成！报告保存到：$OUTPUT_DIR"
