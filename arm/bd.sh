#!/bin/bash

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

# ===================== 安装 BDInfo =====================
install_bdinfo() {
    if ! command -v BDInfo &>/dev/null; then
        local arch=$(uname -m)
        local bdinfo_url=""
        
        if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
            echo "检测到 ARM64 架构，正在安装 BDInfo..." >&2
            bdinfo_url="$BDINFO_URL_ARM64"
        else
            echo "检测到 x86_64 架构，正在安装 BDInfo..." >&2
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
    fi
}

# ===================== 检测输入类型 =====================
get_input_type() {
    local input="$1"
    if [ -f "$input" ]; then
        local ext=$(echo "$input" | awk -F. '{if (NF>1) print tolower($NF)}')
        case "$ext" in
            mkv|mp4|avi|mov|flv|wmv|m4v|ts|m2ts) echo "video"; return 0;;
            iso) echo "iso"; return 0;;
        esac
        echo "bdfile"
    elif [ -d "$input" ]; then
        if [ -d "$input/BDMV" ]; then
            echo "bdmv"
        elif [ -d "$input/VIDEO_TS" ]; then
            echo "dvd"
        else
            local iso_file=$(find "$input" -maxdepth 1 -type f \( -iname "*.iso" \) | head -1)
            if [ -n "$iso_file" ]; then
                echo "iso"
            else
                local video_file=$(find "$input" -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.ts" -o -iname "*.m2ts" \) | head -1)
                if [ -n "$video_file" ]; then
                    echo "video_file:$video_file"
                else
                    echo "错误：无有效视频/BD文件" >&2
                    exit 1
                fi
            fi
        fi
    else
        echo "错误：无效路径" >&2
        exit 1
    fi
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
    install_bdinfo
    local bdinfo_file="$TEMPDIR/bdinfo_$$.txt"
    echo "正在提取 BD 信息..." >&2
    
    # 执行 BDInfo
    if BDInfo -p "$target" -o "$bdinfo_file"; then
        cp "$bdinfo_file" "${OUTPUT_DIR}/bdinfo.txt"
        parse_bdinfo < "$bdinfo_file"
        rm -f "$bdinfo_file"
        
        # ✅ 执行成功：删除 debug 日志
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

if [[ "$type" == "bdmv" ]]; then
    extract_bd_info "$input_path"
elif [[ "$type" == "iso" ]]; then
    echo "挂载 ISO..."
    sudo mount -o loop "$input_path" "$MOUNT_POINT"
    extract_bd_info "$MOUNT_POINT"
elif [[ "$type" == "video" ]]; then
    echo "普通视频，无需 BDInfo 扫描"
else
    echo "不支持的格式"
    exit 1
fi
