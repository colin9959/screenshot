#!/bin/bash
set -e

OUTPUT_DIR="/home/screenshot"
TMP_LIST="/tmp/m2ts_list.txt"
rm -f "$TMP_LIST"
mkdir -p "$OUTPUT_DIR"

# 显示从大到小的 m2ts（但我们取它的 BDMV 目录）
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

# 🔥 核心修复：BDInfo 只能扫 BDMV 文件夹，不能扫单个 m2ts
scan_bdmv() {
  local m2tsfile="$1"
  local bdmv_dir="${m2tsfile%/BDMV/*}/BDMV"
  local name="$(basename "${m2tsfile%.m2ts}")"

  echo -e "\n正在扫描 BDMV 目录：$bdmv_dir"
  BDInfo -p "$bdmv_dir" -o "$OUTPUT_DIR/bdinfo_$name.txt"
  echo "✅ 扫描完成！报告保存到：$OUTPUT_DIR/bdinfo_$name.txt"
}

select_menu() {
  echo -e "=====================================\n"
  read -p "输入序号扫描，q 退出：" sel
  [[ "$sel" == "q" ]] && exit 0

  mapfile -t arr < "$TMP_LIST"
  for i in $sel; do
    scan_bdmv "${arr[$i-1]}"
  done
}

[[ $# -ne 1 ]] && { echo "用法：$0 <蓝光目录>"; exit 1; }
show_list "$1"
select_menu
