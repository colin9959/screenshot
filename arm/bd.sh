#!/bin/bash
set -e

OUTPUT_DIR="/home/screenshot"
TMP_LIST="/tmp/m2ts_list.txt"
TMP_COPY="/tmp/temp_m2ts"
rm -f "$TMP_LIST"
mkdir -p "$OUTPUT_DIR" "$TMP_COPY"

install_bdinfo() {
  if command -v BDInfo &>/dev/null; then
    echo "BDInfo 已就绪"
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

show_list() {
  echo -e "\n====================================="
  echo " m2ts 文件列表"
  echo "====================================="
  idx=1

  find "$1" -type f -iname "*.m2ts" | while read -r file; do
    size=$(numfmt --to=iec $(stat -c "%s" "$file"))
    echo "[$idx] $size | $file"
    echo "$file" >> "$TMP_LIST"
    idx=$((idx+1))
  done
}

select_and_scan() {
  echo -e "=====================================\n"
  read -p "请输入序号（如 1 2 3，q 退出）：" sel
  [[ "$sel" == "q" ]] && exit 0

  mapfile -t arr < "$TMP_LIST"

  for i in $sel; do
    file="${arr[$i-1]}"
    name=$(basename "$file")
    tmpfile="$TMP_COPY/$name"

    echo -e "\n正在处理：$name"
    \cp -f "$file" "$tmpfile"

    echo "正在扫描：$tmpfile"
    BDInfo -p "$tmpfile" -o "$OUTPUT_DIR/bdinfo_${name%.m2ts}.txt"
    
    echo "✅ 保存成功：$OUTPUT_DIR/bdinfo_${name%.m2ts}.txt"
    rm -f "$tmpfile"
  done
}

# 主程序
[[ $# -ne 1 ]] && { echo "用法：$0 <蓝光目录>"; exit 1; }
install_bdinfo
show_list "$1"
select_and_scan

rm -rf "$TMP_COPY"
