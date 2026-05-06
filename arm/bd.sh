#!/bin/bash

# 检查是否传入视频路径
if [ $# -ne 1 ]; then
    echo "用法：$0 <视频目录路径>"
    exit 1
fi

VIDEO_PATH="$1"

# 执行 bdinfo 扫描
echo "正在扫描蓝光目录：$VIDEO_PATH"
bdinfo -p "$VIDEO_PATH" -o "$VIDEO_PATH"

# 定位生成的 .bdinfo 文件（在视频目录的上级目录）
PARENT_DIR=$(dirname "$VIDEO_PATH")
BDINFO_FILE=$(find "$PARENT_DIR" -maxdepth 1 -type f -name "*.bdinfo" | head -n 1)

# 显示内容并自动删除
if [ -n "$BDINFO_FILE" ] && [ -f "$BDINFO_FILE" ]; then
    echo -e "\n========== BDINFO 扫描结果 ==========\n"
    cat "$BDINFO_FILE"
    echo -e "\n=====================================\n"

    # 删除文件
    rm -f "$BDINFO_FILE"
    echo "✅ 已展示并删除临时文件：$BDINFO_FILE"
else
    echo -e "\n❌ 错误：未找到生成的 .bdinfo 文件"
    exit 1
fi
