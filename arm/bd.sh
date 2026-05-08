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

# ===================== 获取所有 m2ts 并按大小排序 =====================
get_all_m2ts_sorted() {
    local bd_path="$1"
    find "$bd_path" -type f -iname "*.m2ts" | xargs ls -lhS | awk '{print $5"\t"$NF}'
}

# ===================== 选择要扫描的 m2ts 序号（支持多选，q 退出） =====================
select_m2ts_files() {
    local bd_path="$1"
    echo -e "\n==================== 找到所有 m2ts 文件（按大小从大到小排序）===================="
    local file_list=()
    local i=1

    while IFS=$'\t' read -r size filepath; do
        file_list+=("$filepath")
        echo -e "[$i]\t大小：$size\t文件：$filepath"
        ((i++))
    done < <(get_all_m2ts_sorted "$bd_path")

    if [ ${#file_list[@]} -eq 0 ]; then
        echo "错误：未找到任何 m2ts 文件" >&2
        exit 1
    fi

    echo -e "==========================================================================="
    echo "提示：输入序号多选（用空格分隔），输入 q 结束选择并开始扫描"
    echo -e "===========================================================================\n"

    local selected_indexes=()
    while true; do
        read -p "请输入选择的序号（q 确认）：" input
        if [[ "$input" == "q" || "$input" == "Q" ]]; then
            break
        fi
        for idx in $input; do
            if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le ${#file_list[@]} ]; then
                selected_indexes+=("$idx")
            else
                echo "无效序号：$idx，已跳过"
            fi
        done
    done

    # 去重
    selected_indexes=($(echo "${selected_indexes[@]}" | tr ' ' '\n' | sort -nu | tr '\n' ' '))

    if [ ${#selected_indexes[@]} -eq 0 ]; then
        echo "未选择任何文件，退出"
        exit 0
    fi

    local selected_files=()
    for idx in "${selected_indexes[@]}"; do
        selected_files+=("${file_list[$idx-1]}")
    done

    echo -e "\n你已选择以下 ${#selected_files[@]} 个文件："
    for f in "${selected_files[@]}"; do
        echo " → $f"
    done

    echo "${selected_files[@]}"
}

# ===================== 检测输入类型 =====================
get_input_type() {
    local input="$1"
    if [ -f "$input" ]; then
        local ext=$(echo "$input" | awk -F. '{if (NF>1) print tolower($NF)}')
        case "$ext" in
            mkv|mp4|avi|mov|flv|wmv|m4v|ts) echo "video"; return 0;;
            iso) echo "iso"; return 0;;
            m2ts) echo "m2ts_file"; return 0;;
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
                local video_file=$(find "$input" -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.ts" \) | head -1)
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

# ===================== 扫描单个 m2ts =====================
scan_single_m2ts() {
    local m2ts_path="$1"
    local filename=$(basename "$m2ts_path" .m2ts)
    local bdinfo_file="$TEMPDIR/bdinfo_$$_$filename.txt"

    echo -e "\n============================================="
    echo "正在扫描：$m2ts_path"
    echo "============================================="

    if BDInfo -p "$m2ts_path" -o "$bdinfo_file"; then
        cp "$bdinfo_file" "${OUTPUT_DIR}/bdinfo_$filename.txt"
        parse_bdinfo < "$bdinfo_file"
        rm -f "$bdinfo_file"
    else
        echo "警告：$m2ts_path 扫描失败" >&2
    fi
}

# ===================== 批量扫描选中的 m2ts =====================
batch_scan_m2ts() {
    local files=("$@")
    for f in "${files[@]}"; do
        scan_single_m2ts "$f"
    done
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

# ===================== 主程序 =====================
if [[ $# -ne 1 ]]; then
    echo "用法：$0 <蓝光目录/ISO文件>"
    echo "功能：列出所有m2ts并按大小排序 → 多选序号 → 批量扫描"
    exit 1
fi

input_path="$1"
type=$(get_input_type "$input_path")
install_bdinfo

if [[ "$type" == "bdmv" ]]; then
    selected_files=($(select_m2ts_files "$input_path"))
    batch_scan_m2ts "${selected_files[@]}"

elif [[ "$type" == "iso" ]]; then
    echo "挂载 ISO..."
    sudo mount -o loop "$input_path" "$MOUNT_POINT"
    selected_files=($(select_m2ts_files "$MOUNT_POINT"))
    batch_scan_m2ts "${selected_files[@]}"

elif [[ "$type" == "video" ]]; then
    echo "普通视频，无需 BDInfo 扫描"

else
    echo "不支持的格式"
    exit 1
fi

echo -e "\n所有选中文件扫描完成！结果保存在：$OUTPUT_DIR"
