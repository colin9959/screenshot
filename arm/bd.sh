#!/bin/bash
set -e

# 基础配置
OUTPUT_DIR="/home/screenshot"
TMP_LIST="/tmp/m2ts_list.txt"
rm -f "$TMP_LIST"
mkdir -p "$OUTPUT_DIR"

# 安装 BDInfo
install_bdinfo() {
  if command -v BDInfo &>/dev/null; then
    echo "BDInfo 已安装"
    return
  fi

  echo "安装 BDInfo..."
  arch=$(uname -m)
  if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
    wget -q -O /tmp/bd.zip https://github.com/colin9959/BDInfo/releases/download/1.0.0/bdinfo_linux_arm64_v2.0.6.zip
  else
    wget -q -O /tmp/bd.zip https://github.com/dotnetcorecorner/BDInfo/releases/download/linux-2.0.6/bdinfo_linux_v2.0.6.zip
  fi

  unzip -q -o /tmp/bd.zip -d /tmp
  chmod +x /tmp/BDInfo*
  cp /tmp/BDInfo* /usr/local/bin/
}

# 显示 m2ts 列表（完美支持空格路径）
show_m2ts() {
  echo -e "\n====================================="
  echo " m2ts 文件列表（从大到小）"
  echo "====================================="

  index=1
  # 用 find + stat 安全获取文件大小，支持空格
  while IFS= read -r -d '' file; do
    size=$(numfmt --to=iec $(stat -c "%s" "$file"))
    echo "[$index] $size : $file"
    echo "$file" >> "$TMP_LIST"
    index=$((index+1))
  done < <(find "$1" -type f -iname "*.m2ts" -print0 | sort -z -k1,1nr)
}

# 选择并扫描
scan_selected() {
  echo -e "=====================================\n"
  read -p "请输入序号（例如 1 2 3，q 退出）：" sel

  if [[ "$sel" == "q" ]]; then
    exit 0
  fi

  # 读取列表
  mapfile -t file_list < "$TMP_LIST"

  for num in $sel; do
    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#file_list[@]} )); then
      file="${file_list[$((num-1))]}"
      echo -e "\n正在扫描：$file"
      name=$(basename "$file" .m2ts)
      BDInfo -p "$file" -o "$OUTPUT_DIR/bdinfo_$name.txt"
      echo "✅ 保存成功：$OUTPUT_DIR/bdinfo_$name.txt"
    fi
  done
}

# 主程序
if [[ $# -ne 1 ]]; then
  echo "用法：$0 <蓝光目录>"
  exit 1
fi

install_bdinfo
show_m2ts "$1"
scan_selected

rm -f "$TMP_LIST"
