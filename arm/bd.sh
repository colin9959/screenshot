#!/bin/bash
set -e

OUTPUT_DIR="/home/screenshot"
TMP_LIST="/tmp/m2ts_list.txt"
rm -f "$TMP_LIST"
mkdir -p "$OUTPUT_DIR"

# 显示文件列表（从大到小）
show_list() {
  echo -e "\n====================================="
  echo " m2ts 文件（从大到小排序）"
  echo "====================================="
  idx=1

  find "$1" -type f -iname "*.m2ts" | while read -r file; do
    stat -c "%s $file" "$file"
  done | sort -nr | cut -d' ' -f2- | while read -r file; do
    size_h=$(numfmt --to=iec $(stat -c "%s" "$file"))
    echo "[$idx] $size_h | $(basename "$file")"
    echo "$file" >> "$TMP_LIST"
    ((idx++))
  done
}

# 🔥 唯一稳定方案：直接扫整个BDMV，但输出文件以选中的m2ts命名
scan_bdmv_with_name() {
  local m2tsfile="$1"
  local bdmv_dir="${m2tsfile%/BDMV/*}/BDMV"
  local outname="bdinfo_$(basename "${m2tsfile%.m2ts}")"

  echo -e "\n====================================="
  echo "正在扫描：$(basename "$m2tsfile")"
  echo "====================================="

  BDInfo -p "$bdmv_dir" -o "$OUTPUT_DIR/$outname.txt"
  echo "✅ 扫描完成 → $OUTPUT_DIR/$outname.txt"
}

# 选择序号
select_menu() {
  echo -e "=====================================\n"
  read -p "输入序号扫描，q 退出：" sel
  [[ "$sel" == "q" ]] && exit 0

  mapfile -t arr < "$TMP_LIST"
  for i in $sel; do
    scan_bdmv_with_name "${arr[$i-1]}"
  done
}

# 入口
[[ $# -ne 1 ]] && { echo "用法：$0 <蓝光目录>"; exit 1; }
show_list "$1"
select_menu
