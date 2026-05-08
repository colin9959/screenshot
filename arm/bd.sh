#!/bin/bash
set -e

OUTPUT_DIR="/home/screenshot"
TMP_LIST="/tmp/m2ts_list.txt"
rm -f "$TMP_LIST"
mkdir -p "$OUTPUT_DIR"

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

# 🔥 真正单独扫单个 m2ts（修复 BDInfo 无法直接扫的问题）
scan_single_m2ts() {
  local m2ts="$1"
  local name=$(basename "$m2ts" .m2ts)
  local tmp_bdmv="/tmp/BDINFO_SCAN"

  rm -rf "$tmp_bdmv"
  mkdir -p "$tmp_bdmv/STREAM"
  ln -s "$m2ts" "$tmp_bdmv/STREAM/00001.m2ts"

  echo -e "\n正在单独扫描：$(basename "$m2ts")"
  BDInfo -p "$tmp_bdmv" -o "$OUTPUT_DIR/bdinfo_$name.txt"
  echo "✅ 完成：$OUTPUT_DIR/bdinfo_$name.txt"

  rm -rf "$tmp_bdmv"
}

select_menu() {
  echo -e "=====================================\n"
  read -p "输入序号扫描，q 退出：" sel
  [[ "$sel" == "q" ]] && exit 0

  mapfile -t arr < "$TMP_LIST"
  for i in $sel; do
    scan_single_m2ts "${arr[$i-1]}"
  done
}

[[ $# -ne 1 ]] && { echo "用法：$0 <蓝光目录>"; exit 1; }
show_list "$1"
select_menu
