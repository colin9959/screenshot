#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法：$0 <视频目录或ISO文件路径>"
    exit 1
fi

BD_PATH="$1"

# 判断是目录 还是 ISO 文件
if [ -d "$BD_PATH" ]; then
    # ==============================================
    # 情况1：是光盘目录 → 执行 bdinfo BD_PATH
    # ==============================================
    echo "🔍 扫描蓝光目录：$BD_PATH"
    bdinfo "$BD_PATH"

    # 查找生成的 BDINFO.*.txt 文件
    bdinfo_file=$(find "$BD_PATH" -maxdepth 1 -type f -name "BDINFO.*.txt" | head -n 1)

elif [ -f "$BD_PATH" ] && [[ "$BD_PATH" =~ \.iso$|\.ISO$ ]]; then
    # ==============================================
    # 情况2：是 ISO 文件 → 执行 bdinfo BD_PATH /tmp
    # ==============================================
    echo "🔍 扫描ISO文件：$BD_PATH"
    bdinfo "$BD_PATH" /tmp

    # 查找 /tmp 下的 BDINFO.*.txt
    bdinfo_file=$(find /tmp -maxdepth 1 -type f -name "BDINFO.*.txt" | head -n 1)

else
    echo "❌ 路径无效，不是目录也不是ISO文件"
    exit 1
fi

# ==============================================
# 显示内容 + 删除文件
# ==============================================
if [ -n "$bdinfo_file" ] && [ -f "$bdinfo_file" ]; then
    echo -e "\n==================== BDINFO 结果 ====================\n"
    cat "$bdinfo_file"
    echo -e "\n=====================================================\n"

    rm -f "$bdinfo_file"
    echo "✅ 已展示并删除文件：$bdinfo_file"
else
    echo -e "\n❌ 未找到 BDINFO 输出文件"
    exit 1
fi
