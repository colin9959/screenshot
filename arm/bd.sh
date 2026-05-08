#!/bin/bash

# ===================== 固定配置 =====================
BDINFO_URL_X64="https://github.com/dotnetcorecorner/BDInfo/releases/download/linux-2.0.6/bdinfo_linux_v2.0.6.zip"
BDINFO_URL_ARM64="https://github.com/colin9959/BDInfo/releases/download/1.0.0/bdinfo_linux_arm64_v2.0.6.zip"
INSTALL_DIR="/usr/local/bin"

OUTPUT_DIR="/home/screenshot"
MOUNT_POINT="/mnt/iso"
TEMPDIR="/tmp/bdinfo_temp_$$"

mkdir -p "$OUTPUT_DIR" "$MOUNT_POINT" "$TEMPDIR"

# ===================== 安装 BDInfo =====================
install_bdinfo() {
    if ! command -v BDInfo &>/dev/null; then
        local arch=$(uname -m)
        local bdinfo_url=""
        
        if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
            echo "检测到 ARM64 架构，正在安装 BDInfo..."
            bdinfo_url="$BDINFO_URL_ARM64"
        else
            echo "检测到 x86_64 架构，正在安装 BDInfo..."
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
                echo "BDInfo 安装成功！"
                rm -rf "$TEMPDIR"
                mkdir -p "$TEMPDIR"
                return 0
            fi
        done
        echo "错误：无法下载 BDInfo"
        exit 1
    fi
}

# ===================== 获取所有 m2ts 按大小排序 =====================
get_sorted_m2ts() {
    local path="$1"
    find "$path" -type f -iname "*.m2ts" -print0 | sort -z -k1,1nr | while IFS= read -r -d '' file; do
        size=$(du -h "$file" | awk '{print $1}')
        echo "$size"$'\t'"$file"
    done | sort -rh
}

# ===================== 选择 m2ts（交互菜单） =====================
select_files() {
    local bd_path="$1"
    mapfile -t lines < <(get_sorted_m2ts "$bd_path")
    declare -a files=()

    echo -e "\n========== 所有 m2ts 文件（从大到小）=========="
    for i in "${!lines[@]}"; do
        IFS=$'\t' read -r size filepath <<< "${lines[$i]}"
        files[$i]="$filepath"
        echo "[$((i+1))]  $size  $filepath"
    done

    echo -e "\n输入序号多选（空格分隔），输入 q 开始扫描"
    read -p "请选择：" input

    [[ "$input" == "q" || -z "$input" ]] && exit 0

    declare -a selected=()
    for idx in $input; do
        if [[ $idx =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#files[@]} )); then
            selected+=("${files[$idx-1]}")
        fi
    done

    selected=($(printf "%s\n" "${selected[@]}" | sort -u))
    echo -e "\n已选择 ${#selected[@]} 个文件："
    printf " → %s\n" "${selected[@]}"
    echo "${selected[@]}"
}

# ===================== 扫描单个 m2ts =====================
scan_one() {
    local file="$1"
    local name=$(basename "$file" .m2ts)
    local out="$TEMPDIR/$name.txt"

    echo -e "\n====================================="
    echo "扫描：$file"
    echo "====================================="

    if BDInfo -p "$file" -o "$out" 2>/dev/null; then
        cp "$out" "$OUTPUT_DIR/bdinfo_$name.txt"
        awk '
        BEGIN{RS="DISC INFO:";max=0;best=""}
        NR>1{
            s=$0; sub(/FILES:.*/,"",s)
            if(match(s,/Size:[ ]*([0-9,]+)/)) {
                n=gensub(/,/,"","g",substr(s,RSTART+5,RLENGTH-5))
                if(n+0>max) {max=n;best=s}
            }
        }
        END{
            if(best!="") {
                sub(/[ ]+$/,"",best)
                print "----- BDInfo 信息 -----"
                print best
                print "-----------------------"
            }
        }' "$out"
    else
        echo "⚠️  扫描失败"
    fi
    rm -f "$out"
}

# ===================== 批量扫描 =====================
batch_scan() {
    for f in "$@"; do
        scan_one "$f"
    done
}

# ===================== 清理 =====================
cleanup() {
    mountpoint -q "$MOUNT_POINT" && sudo umount "$MOUNT_POINT" 2>/dev/null
    rm -rf "$TEMPDIR"
}
trap cleanup EXIT

# ===================== 主程序 =====================
if [[ $# -ne 1 ]]; then
    echo "用法：$0 <蓝光目录/ISO文件>"
    exit 1
fi

input="$1"
install_bdinfo

if [[ -d "$input/BDMV" ]]; then
    selected=($(select_files "$input"))
    batch_scan "${selected[@]}"
elif [[ "${input##*.}" == "iso" ]]; then
    echo "挂载 ISO..."
    sudo mount -o loop "$input" "$MOUNT_POINT"
    selected=($(select_files "$MOUNT_POINT"))
    batch_scan "${selected[@]}"
else
    echo "不支持的格式"
    exit 1
fi

echo -e "\n✅ 全部扫描完成！报告保存到：$OUTPUT_DIR"
