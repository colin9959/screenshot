#!/bin/bash
set -e

# 配置
OUTPUT_DIR="/home/screenshot"
TMP_FILE="/tmp/m2ts_ready.txt"
rm -f "$TMP_FILE"
mkdir -p "$OUTPUT_DIR"

# 安装 BDInfo
install_bdinfo() {
  if command -v BDInfo &>/dev/null; then return; fi
  echo "安装 BDInfo..."

  arch=$(uname -m)
  if [[ "$arch" == @(aarch64|arm64) ]]; then
    wget -q -O /tmp/bd.zip https://github.com/colin9959/BDInfo/releases/download/1.0.0/bdinfo_linux_arm64_v2.0.6.zip
  else
    wget -q -O /tmp/bd.zip https://github.com/dotnetcorecorner/BDInfo/releases/download/linux-2.0.6/bdinfo_linux_v2.0.6.zip
  fi

  unzip -q -o /tmp/bd.zip -d /tmp
  chmod +x /tmp/BDInfo*
  cp /tmp/BDInfo* /usr/local/bin/
}

# 生成列表（100% 支持空格，无 ls 无 xargs）
make_list() {
  echo -e "\n====================================="
  echo " 找到的 m2ts 文件（从大到小）"
  echo "====================================="

  index=1
  # 只使用 find -print0，绝对安全
  while IFS= read -r -d '' file; do
    size_bytes=$(stat -c "%s" "$file")
    size_human=$(numfmt --to=iec "$size_bytes")
    echo "[$index] $size_human | $file"
    echo "$file" >> "$TMP_FILE"
    ((index++))
  done < <(find "$1" -type f -iname "*.m2ts" -print0 | sort -z -r)
}

# 选择并扫描
do_scan() {
  echo -e "=====================================\n"
  read -p "输入序号（1 2 3），q 退出：" sel
  [[ "$sel" == "q" ]] && exit 0

  mapfile -t list_arr < "$TMP_FILE"

  for idx in $sel; do
    if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#list_arr[@]} )); then
      f="${list_arr[$((idx-1))]}"
      echo -e "\n▶ 扫描：$f"
      name=$(basename "$f" .m2ts)
      BDInfo -p "$f" -o "$OUTPUT_DIR/bdinfo_$name.txt"
      echo "✅ 完成：$OUTPUT_DIR/bdinfo_$name.txt"
    fi
  done
}

# 入口
[[ $# -ne 1 ]] && { echo "用法：$0 <蓝光目录>"; exit 1; }
install_bdinfo
make_list "$1"
do_scan
rm -f "$TMP_FILE"
