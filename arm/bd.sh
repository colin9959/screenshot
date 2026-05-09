#!/bin/bash

# ===================== 固定配置 =====================
INSTALL_DIR="/usr/local/bin"
OUTPUT_DIR="/home/screenshot"
MOUNT_POINT="/mnt/iso"
TEMPDIR="/tmp/bdinfo_temp_$$"

# 必须创建目录
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMPDIR"

# ===================== 【修复】检测输入类型 =====================
get_input_type() {
    local input="$1"
    if [ -d "$input" ] && [ -d "$input/BDMV" ]; then
        echo "bdmv"
        return 0
    fi
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
            sub(/[[:space:]]+$/,"best_section");
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

    # 【核心修复】BDInfo 只能输出到当前目录的 bdinfo.txt
    local output_txt="bdinfo.txt"
    echo "正在提取 BD 信息..." >&2

    # 进入临时目录执行（防止污染系统）
    cd "$TEMPDIR" || exit 1

    # 正确用法：BDInfo 不支持 -o 参数！直接运行
    if BDInfo -p "$target"; then
        sleep 0.5

        # 检查是否生成文件
        if [ ! -f "$output_txt" ]; then
            echo "错误：BDInfo 未生成报告" >&2
            exit 1
        fi

        # 复制到目标目录
        cp "$output_txt" "${OUTPUT_DIR}/bdinfo.txt"
        # 前端显示
        parse_bdinfo < "$output_txt"
        # 清理
        rm -f "$output_txt"
        rm -f /usr/local/bin/debug_*.log
    else
        echo "错误：BDInfo 执行失败" >&2
        exit 1
    fi
}

# ===================== 清理 =====================
cleanup() {
    sync
    sleep 1
    if mountpoint -q "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT" 2>/dev/null || true
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

# 生成干净文件名
get_clean_filename() {
    local raw="$1"
    local name=$(basename "$raw")
    name="${name%.*}"
    name=$(echo "$name" | sed 's/[^a-zA-Z0-9_-]/_/g' | sed 's/__*/_/g')
    echo "$name"
}
clean_name=$(get_clean_filename "$input_path")

# 执行
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

# 重命名
if [ -f "${OUTPUT_DIR}/bdinfo.txt" ]; then
    mv -f "${OUTPUT_DIR}/bdinfo.txt" "${OUTPUT_DIR}/${clean_name}-bdinfo.txt"
    echo -e "\n✅ 文件已保存：${OUTPUT_DIR}/${clean_name}-bdinfo.txt"
fi
