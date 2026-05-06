#!/bin/bash

# 检查是否传入视频路径
if [ $# -ne 1 ]; then
    echo "用法：$0 <视频目录路径/ISO文件路径>"
    exit 1
fi

INPUT_PATH="$1"

# ===================== 核心修改：判断是否为 ISO 文件 =====================
if [ -f "$INPUT_PATH" ] && [[ "$INPUT_PATH" =~ \.iso$|\.ISO$ ]]; then
    # ========== 处理 ISO 文件：输出到 ISO 所在目录，文件名为 ISO 名（无后缀） ==========
    echo "正在扫描 ISO 文件：$INPUT_PATH"
    ISO_DIR=$(dirname "$INPUT_PATH")          # ISO 所在目录
    ISO_NAME=$(basename "$INPUT_PATH" | sed 's/\.iso$//I')  # 去掉 .iso 后缀
    BDINFO_FILE="${ISO_DIR}/${ISO_NAME}"      # 最终输出文件（无后缀）
    
    # 执行 bdinfo（ISO 专用）
    bdinfo -p "$INPUT_PATH" -o "$ISO_DIR"

else
    # ========== 原有逻辑：处理普通目录 ==========
    echo "正在扫描蓝光目录：$INPUT_PATH"
    bdinfo -p "$INPUT_PATH" -o "$INPUT_PATH"

    # 定位生成的 .bdinfo 文件（在视频目录的上级目录）
    PARENT_DIR=$(dirname "$INPUT_PATH")
    BDINFO_FILE=$(find "$PARENT_DIR" -maxdepth 1 -type f -name "*.bdinfo" | head -n 1)
fi

# ===================== 显示内容 + 自动删除（通用） =====================
if [ -n "$BDINFO_FILE" ] && [ -f "$BDINFO_FILE" ]; then
    echo -e "\n========== BDINFO 扫描结果 ==========\n"
    cat "$BDINFO_FILE"
    echo -e "\n=====================================\n"

    # 删除文件
    rm -f "$BDINFO_FILE"
    echo "✅ 已展示并删除临时文件：$BDINFO_FILE"
else
    echo -e "\n❌ 错误：未找到生成的 BDINFO 文件"
    exit 1
fi
