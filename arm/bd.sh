#!/bin/bash

# ===================== 固定配置 =====================

INSTALL_DIR="/usr/local/bin"
OUTPUT_DIR="/home/screenshot"
MOUNT_POINT="/mnt/iso"
TEMPDIR="/tmp/bdinfo_temp_$$"

# 创建目录
mkdir -p "$OUTPUT_DIR"
mkdir -p "$MOUNT_POINT"
mkdir -p "$TEMPDIR"

# ===================== 【修复】检测输入类型 =====================
get_input_type() {
    local input="$1"

    # 先判断是不是目录
    if [ -d "$input" ]; then
        # 只要目录里有 BDMV 文件夹，就判定为蓝光目录
        if [ -d "$input/BDMV" ] || [ -d "$input/../BDMV" ]; then
            echo "bdmv"
            return 0
        fi
    fi

    # 其他判断不变
    if [ -f "$input" ]; then
        local ext=$(echo "$input" | awk -F. '{if (NF>1) print tolower($NF)}')
        case "$ext" in
            mkv|mp4|avi|mov|flv|wmv|m4v|ts|m2ts) echo "video"; return 0;;
            iso) echo "iso"; return 0;;
        esac
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
            sub(/[[:space:]]+$/,"",best_section);
            print "↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓ BDInfo 信息 ↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓";
            print best_section;
            print "↑#↑#↑#↑#↑#↑#↑#↑#↑#↑#↑ 分割线 ↑#↑#↑#↑#↑#↑#↑#↑#↑#↑#↑";
        } else {
            print "错误：无有效PLAYLIST" > "/dev/stderr";
            exit 1;
        }
    }'
}

# ===================== 提取 BD 信息 =====================
extract_bd_info() {
    local target="$1"
    local bdinfo_file="$TEMPDIR/bdinfo_$$.txt"
    echo "正在提取 BD 信息..." >&2
    
    # 执行 BDInfo
    if BDInfo -p "$target" -o "$bdinfo_file"; then
        cp "$bdinfo_file" "${OUTPUT_DIR}/bdinfo.txt"
        parse_bdinfo < "$bdinfo_file"
        rm -f "$bdinfo_file"
        
        # 执行成功：删除 debug 日志
        rm -f /usr/local/bin/debug_*.log
    else
        echo "错误：BDInfo 执行失败" >&2
        exit 1
    fi
}

# ===================== 清理 =====================
cleanup() {
    if mountpoint -q "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT" 2>/dev/null || true
    fi
    rm -rf "$MOUNT_POINT" "$TEMPDIR"
    wait 2>/dev/null || true
}
trap cleanup EXIT

# ===================== 主程序（可直接运行） =====================
if [[ $# -ne 1 ]]; then
    echo "用法：$0 <蓝光目录/ISO文件>"
    exit 1
fi

input_path="$1"
type=$(get_input_type "$input_path")

# 生成干净文件名
get_clean_filename() {
    local raw="$1"
    local name=$(basename "$raw")
    name="${name%.*}"
    name=$(echo "$name" | sed 's/[^a-zA-Z0-9_-]/_/g' | sed 's/__*/_/g')
    echo "$name"
}
clean_name=$(get_clean_filename "$input_path")

# 执行扫描
if [[ "$type" == "bdmv" ]]; then
    extract_bd_info "$input_path"
elif [[ "$type" == "iso" ]]; then
    echo "挂载 ISO..."
    sudo mount -o loop "$input_path" "$MOUNT_POINT"
    extract_bd_info "$MOUNT_POINT"
elif [[ "$type" == "video" ]]; then
    echo "普通视频，无需 BDInfo 扫描"
    exit 0
else
    echo "错误：不是有效的蓝光目录/ISO文件"
    exit 1
fi

# 重命名文件
if [ -f "${OUTPUT_DIR}/bdinfo.txt" ]; then
    mv -f "${OUTPUT_DIR}/bdinfo.txt" "${OUTPUT_DIR}/${clean_name}-bdinfo.txt"
    echo -e "\n✅ 文件已保存：${OUTPUT_DIR}/${clean_name}-bdinfo.txt"
fi
