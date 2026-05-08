#!/bin/bash

# 基础目录
OUTPUT_DIR="/home/screenshot"
MOUNT_POINT="/mnt/iso"
TMPLIST="/tmp/m2ts_list.txt"
rm -f $TMPLIST
mkdir -p $OUTPUT_DIR $MOUNT_POINT

# 安装 BDInfo
install_bdinfo() {
  if command -v BDInfo >/dev/null 2>&1; then return; fi
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

# 显示所有 m2ts 文件
show_list() {
  echo "====================================="
  echo " m2ts 文件列表（从大到小）"
  echo "====================================="
  idx=1
  find "$1" -type f -iname "*.m2ts" | xargs ls -lhS | awk '{print $5, $9}' | while read size file; do
    echo "[$idx] $size $file"
    echo "$file" >> $TMPLIST
    idx=$((idx+1))
  done
  echo "====================================="
}

# 选择并扫描
scan_selected() {
  read -p "请输入序号（例如 1 2 3，q 退出）：" sel
  if [ "$sel" = "q" ]; then exit 0; fi

  for n in $sel; do
    file=$(sed -n "${n}p" $TMPLIST)
    echo "扫描：$file"
    name=$(basename "$file" .m2ts)
    BDInfo -p "$file" -o "$OUTPUT_DIR/bdinfo_$name.txt"
    echo "完成：$OUTPUT_DIR/bdinfo_$name.txt"
  done
}

# 主程序
if [ $# -ne 1 ]; then
  echo "用法：$0 蓝光目录"
  exit 1
fi

install_bdinfo
show_list "$1"
scan_selected

rm -f $TMPLIST
