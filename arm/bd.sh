#!/bin/bash

# ===================== 固定配置 =====================
INSTALL_DIR="/usr/local/bin"
OUTPUT_DIR="/home/screenshot"
MOUNT_POINT="/mnt/iso"
TEMPDIR="/tmp/bdinfo_temp_$$"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMPDIR"

# ===================== 检测输入类型 =====================
get_input_type() {
    local input="$1"
    if [ -d "$input" ] && [ -d "$input/BDMV" ]; then
        echo "bdmv"
        return 0
    fi
    if [ -f "$input" ]; then
        local ext="${input##*.}"
        ext=$(echo "$ext" | tr 'A-Z' 'a-z')
        if [ "$ext" = "iso" ]; then echo "iso"; return 0; fi
        if [[ "$ext" =~^(mkv|mp4|avi|mov|flv|wmv|m4v|ts|m2ts)$ ]]; then echo "video"; return 0; fi
    fi
    echo "unknown"
}

# ===================== 解析 BDInfo =====================
parse_bdinfo() {
    awk '
    BEGIN {RS = "DISC INFO:"; max_size=0; best_section=""}
    NR>1 {
        section="DISC INFO:"$0; sub(/FILES:.*/,"",section)
        if(match(section,/Size:[[:space:]]+([0-9,]+)/)){
            size_str=substr(section,RSTART+5,RLENGTH-5); gsub(/,/,"",size_str); size=size_str+0
            if(size>max_size){max_size=size; best_section=section}
        }
    }
    END {
        if(best_section!=""){
            sub(/[[:space:]]+$/,"best_section");
            print "↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓ BDInfo 信息 ↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓";
            print best_section;
            print "↑#↑#↑#↑#↑#↑#↑#↑#↑#↑#↑ 分割线 ↑#↑#↑#↑#↑#↑#↑#↑#↑#↑#↑";
        } else {
            print "错误：无有效PLAYLIST" > "/dev/stderr"; exit 1;
        }
    }'
}

# ===================== 提取 BD 信息 =====================
extract_bd_info() {
    local target="$1"
    echo "正在提取 BD 信息..." >&2

    cd "$TEMPDIR" || exit 1
    rm -f BDInfoReport.txt bdinfo.txt

    # 正确执行 BDInfo
    BDInfo -p "$target"

    sleep 0.8

    # ✅ 真实文件名：BDInfoReport.txt（这是关键修复！）
    if [ -f "BDInfoReport.txt" ]; then
        cp BDInfoReport.txt "${OUTPUT_DIR}/bdinfo.txt"
        parse_bdinfo < BDInfoReport.txt
        rm -f BDInfoReport.txt
        rm -f /usr/local/bin/debug_*.log 2>/dev/null
        return 0
    fi

    echo "错误：BDInfo 未生成报告" >&2
    exit 1
}

# ===================== 清理 =====================
cleanup() {
    sync
    sleep 1
    if mountpoint -q "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT" 2>/dev/null
    fi
    rm -rf "$TEMPDIR"
}
trap cleanup EXIT

# ===================== 主程序 =====================
if [[ $# -ne 1 ]]; then
    echo "用法：$0 <蓝光目录/ISO文件>"
    exit 1
fi

input_path="$1"
type=$(get_input_type "$input_path")

get_clean_filename() {
    local raw="$1"
    local name=$(basename "$raw")
    name="${name%.*}"
    echo "$name" | sed 's/[^a-zA-Z0-9_-]/_/g' | sed 's/__*/_/g'
}
clean_name=$(get_clean_filename "$input_path")

case "$type" in
    bdmv) extract_bd_info "$input_path" ;;
    iso)
        echo "挂载 ISO..."
        sudo mount -o loop "$input_path" "$MOUNT_POINT" 2>/dev/null
        extract_bd_info "$MOUNT_POINT"
        ;;
    video)
        echo "普通视频，无需 BDInfo 扫描"
        exit 0
        ;;
    *)
        echo "错误：不是有效的蓝光目录/ISO文件"
        exit 1
        ;;
esac

if [ -f "${OUTPUT_DIR}/bdinfo.txt" ]; then
    mv -f "${OUTPUT_DIR}/bdinfo.txt" "${OUTPUT_DIR}/${clean_name}-bdinfo.txt"
    echo -e "\n✅ 文件已保存：${OUTPUT_DIR}/${clean_name}-bdinfo.txt"
fi
