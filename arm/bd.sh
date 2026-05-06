#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法：$0 <视频目录/ISO文件路径>"
    exit 1
fi

INPUT_PATH="$1"

# ==============================
# 自动获取目录里最大的文件
# ==============================
get_largest_file() {
    local dir="$1"
    find "$dir" -type f | xargs ls -1S | head -n 1
}

# ==============================
# 判断输入类型：目录 / ISO
# ==============================
if [ -d "$INPUT_PATH" ]; then
    # 目录：自动选最大文件作为扫描目标
    TARGET=$(get_largest_file "$INPUT_PATH")
    echo "🔍 扫描目录：$INPUT_PATH"
    echo "🎯 目标文件：$TARGET"

    # 执行 bdinfo
    bdinfo -p "$TARGET" -o "$TARGET"

    # 找 .bdinfo 文件（上级目录）
    PARENT_DIR=$(dirname "$TARGET")
    BDINFO_FILE=$(find "$PARENT_DIR" -maxdepth 1 -type f -name "*.bdinfo" | head -n 1)

elif [ -f "$INPUT_PATH" ] && [[ "$INPUT_PATH" =~ \.iso$|\.ISO$ ]]; then
    # ISO 文件：直接扫描，输出文件=视频文件名（无后缀），在当前目录
    TARGET="$INPUT_PATH"
    ISO_DIR=$(dirname "$INPUT_PATH")
    ISO_FILENAME=$(basename "$INPUT_PATH" | sed -e 's/\.iso$//I')
    BDINFO_FILE="${ISO_DIR}/${ISO_FILENAME}"

    echo "🔍 扫描 ISO：$INPUT_PATH"
    echo "📄 输出文件：$BDINFO_FILE"

    # 执行 bdinfo
    bdinfo -p "$TARGET" -o "$ISO_DIR"
else
    echo "❌ 无效路径：既不是目录也不是ISO文件"
    exit 1
fi

# ==============================
# 显示内容并删除文件
# ==============================
if [ -n "$BDINFO_FILE" ] && [ -f "$BDINFO_FILE" ]; then
    echo -e "\n========== BDINFO 扫描结果 ==========\n"
    cat "$BDINFO_FILE"
    echo -e "\n=====================================\n"

    rm -f "$BDINFO_FILE"
    echo "✅ 已展示并删除：$BDINFO_FILE"
else
    echo -e "\n❌ 错误：未找到 BDINFO 输出文件"
    exit 1
fi
