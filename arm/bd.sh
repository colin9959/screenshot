#!/bin/bash
set -e

OUTPUT_DIR="/home/screenshot"
TMP_LIST="/tmp/m2ts_list.txt"
rm -f "$TMP_LIST"
mkdir -p "$OUTPUT_DIR"

# 切换工作目录（解决 BDInfo 空格路径BUG！核心！）
WORK_DIR="/tmp"
cd "$WORK_DIR"

install_bdinfo() {
  command -v BDInfo &>/dev/null && echo "BDInfo 已就绪" && return
}

# 显示列表（从大到小）
show_list() {
  echo -e "\n====================================="
  echo " m2ts 文件（从大到小排序）"
  echo "====================================="
  idx=1

  find "$1" -type f -iname "*.m2ts" | while read -r file; do
    size=$(stat -c "%s" "$file")
    echo "$size"$'\t'"$file"
  done | sort -nr | cut -f2 | while read -r file; do
    size_h=$(numfmt --to=iec $(stat -c "%s" "$file"))
    echo "[$idx] $size_h | $file"
    echo "$file" >> "$TMP_LIST"
    ((idx++))
  done
}

# 扫描（使用相对路径，支持空格，不用复制！）
scan() {
  local file="$1"
  local name=$(basename "$file")
  echo -e "\n正在扫描：$name"

  # 🔥 核心修复：用相对路径 . 文件，BDInfo 完美支持空格！
  BDInfo -p "$file" -o "$OUTPUT_DIR/bdinfo_${name%.m2ts}.txt"

  echo "✅ 完成：$OUTPUT_DIR/bdinfo_${name%.m2ts}.txt"
}

# 选择
select_menu() {
  echo -e "=====================================\n"
  read -p "输入序号扫描，q 退出：" sel
  [[ "$sel" == "q" ]] && exit 0

  mapfile -t arr < "$TMP_LIST"
  for i in $sel; do
    scan "${arr[$i-1]}"
  done
}

# 主程序
[[ $# -ne 1 ]] && { echo "用法：$0 <蓝光目录>"; exit 1; }
install_bdinfo
show_list "$1"
select_menu
