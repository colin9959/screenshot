#!/bin/bash
set -e

# 配置
OUTPUT_DIR="/home/screenshot"
MOUNT_POINT="/mnt/iso"
TEMPDIR="/tmp/bdinfo_temp"
mkdir -p "$OUTPUT_DIR" "$MOUNT_POINT" "$TEMPDIR"
rm -f "$TEMPDIR/filelist.txt"

# 安装 BDInfo
install_bdinfo() {
  if command -v BDInfo &>/dev/null; then
    return
  fi

  arch=$(uname -m)
  if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
    wget -q -O "$TEMPDIR/bd.zip" https://github.com/colin9959/BDInfo/releases/download/1.0.0/bdinfo_linux_arm64_v2.0.6.zip
  else
    wget -q -O "$TEMPDIR/bd.zip" https://github.com/dotnetcorecorner/BDInfo/releases/download/linux-2.0.6/bdinfo_linux_v2.0.6.zip
  fi

  unzip -q -o "$TEMPDIR/bd.zip" -d "$TEMPDIR"
  chmod +x "$TEMPDIR"/BDInfo*
  cp "$TEMPDIR"/BDInfo* /usr/local/bin/
}

# 显示所有 m2ts 并生成列表
show_m2ts_list() {
  local path="$1"
  echo -e "\n========== 扫描到的 m2ts 文件（从大到小排序）=========="
  index=1

  while IFS= read -r file; do
    size=$(du -h "$file" | awk '{print $1}')
    echo "[$index]  $size  $file"
    echo "$file" >> "$TEMPDIR/filelist.txt"
    index=$((index+1))
  done < <(find "$path" -type f -iname "*.m2ts" | xargs ls -lhS | awk '{print $NF}')

  echo "====================================================="
}

# 选择文件
select_files() {
  read -p "请输入序号（多选空格分隔，输入 q 开始）： " input
  if [[ "$input" == "q" ]]; then
    exit 0
  fi

  selected=()
  while IFS= read -r line; do
    filelist+=("$line")
  done < "$TEMPDIR/filelist.txt"

  for num in $input; do
    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#filelist[@]} )); then
      selected+=("${filelist[$((num-1))]}")
    fi
  done
}

# 扫描单个
scan_single() {
  local file="$1"
  echo -e "\n正在扫描：$file"
  local name=$(basename "$file" .m2ts)
  BDInfo -p "$file" -o "$TEMPDIR/$name.txt"
  cp "$TEMPDIR/$name.txt" "$OUTPUT_DIR/bdinfo_$name.txt"
  echo "✅ 已保存：$OUTPUT_DIR/bdinfo_$name.txt"
}

# 清理
cleanup() {
  mountpoint -q "$MOUNT_POINT" && umount "$MOUNT_POINT" 2>/dev/null
  rm -rf "$TEMPDIR"
}
trap cleanup EXIT

# 主程序
if [[ $# -ne 1 ]]; then
  echo "用法：$0 <蓝光目录/ISO文件>"
  exit 1
fi

input="$1"
install_bdinfo

# 挂载ISO
if [[ "${input##*.}" == "iso" ]]; then
  echo "挂载ISO..."
  mount -o loop "$input" "$MOUNT_POINT"
  target="$MOUNT_POINT"
else
  target="$input"
fi

# 显示列表（这一步绝对会执行！）
show_m2ts_list "$target"

# 选择
select_files

# 批量扫描
for f in "${selected[@]}"; do
  scan_single "$f"
done

echo -e "\n🎉 全部扫描完成！"
