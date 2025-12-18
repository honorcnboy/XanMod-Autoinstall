#!/bin/bash
# =========================================
# Debian / Ubuntu 安全安装 XanMod 内核 (一键互动版)
# 保留旧内核，自动更新 GRUB，提供关键交互确认
# =========================================

set -e

echo "============================================"
echo "🚀 欢迎使用 XanMod 内核安装脚本（保留旧内核版）"
echo "============================================"

# 1️⃣ 系统更新与安装必要工具
echo -e "\n1️⃣ 系统更新与安装必要工具..."
sudo apt update && sudo apt upgrade -y
sudo apt install gnupg wget -y

# 2️⃣ 添加 XanMod 官方仓库
echo -e "\n2️⃣ 添加 XanMod 官方仓库..."
echo 'deb http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-kernel.list
wget -qO - https://dl.xanmod.org/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/xanmod-kernel.gpg
sudo apt update

# 3️⃣ 查看可用的 XanMod 内核版本
echo -e "\n3️⃣ 查看可用的 XanMod 内核版本..."
apt search linux-xanmod | grep -E "linux-xanmod-(mainline|edge|lts|rt)"
echo
read -rp "请选择要安装的内核类型 [MAIN/EDGE/LTS/RT] (默认 EDGE): " KERNEL_TYPE
KERNEL_TYPE=${KERNEL_TYPE^^}
[[ -z "$KERNEL_TYPE" ]] && KERNEL_TYPE="EDGE"

case "$KERNEL_TYPE" in
    MAIN) KERNEL_TYPE_PKG="mainline" ;;
    EDGE) KERNEL_TYPE_PKG="edge" ;;
    LTS)  KERNEL_TYPE_PKG="lts" ;;
    RT)   KERNEL_TYPE_PKG="rt" ;;
    *) echo "选择无效，使用默认 EDGE"; KERNEL_TYPE_PKG="edge" ;;
esac

echo "✅ 选择的内核类型: $KERNEL_TYPE_PKG"

# 4️⃣ CPU 支持检测与内核版本建议
echo -e "\n4️⃣ CPU 支持检测与内核版本建议..."
CPU_FLAGS=$(lscpu | grep Flags | tr ' ' '\n')

if echo "$CPU_FLAGS" | grep -q avx2; then
    SUGGEST_VER="x64v3"
elif echo "$CPU_FLAGS" | grep -q sse4_2; then
    SUGGEST_VER="x64v2"
else
    SUGGEST_VER="x64v1"
fi

echo "💡 系统检测推荐安装: $SUGGEST_VER"

read -rp "确认使用推荐版本 $SUGGEST_VER 吗？(Y/n) " CONFIRM_VER
if [[ "$CONFIRM_VER" =~ ^[Nn]$ ]]; then
    read -rp "请输入要使用的版本 [x64v1/x64v2/x64v3]:" SUGGEST_VER
fi

echo "✅ 将安装内核版本: $KERNEL_TYPE_PKG $SUGGEST_VER"

# 5️⃣ 安装 XanMod 内核
echo -e "\n5️⃣ 安装 XanMod 内核..."
sudo apt install -y linux-xanmod-$KERNEL_TYPE_PKG-$SUGGEST_VER

echo "✅ 内核安装完成，旧内核仍保留"

# 6️⃣ 检查 GRUB 中可用内核
echo -e "\n6️⃣ 检查 GRUB 中可用内核..."
grep menuentry /boot/grub/grub.cfg | grep -i xanmod
echo
read -rp "是否进行下一步更新 GRUB 并设置默认启动 XanMod 内核? (Y/n) " UPDATE_GRUB
if [[ ! "$UPDATE_GRUB" =~ ^[Nn]$ ]]; then
    # 自动获取新内核名称
    KERNEL_NAME=$(grep "menuentry '.*xanmod" /boot/grub/grub.cfg | head -n1 | sed "s/menuentry '\(.*\)'.*/\1/")
    sudo sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"$KERNEL_NAME\"|g" /etc/default/grub
    sudo sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=5|g" /etc/default/grub
    sudo update-grub
    echo "✅ GRUB 已更新，默认启动内核: $KERNEL_NAME"
else
    echo "⚠️ 跳过 GRUB 更新，请手动确认 GRUB 配置"
fi

# 7️⃣ 重启前确认
read -rp "是否立即重启系统以验证新内核? (Y/n) " REBOOT_CONFIRM
if [[ ! "$REBOOT_CONFIRM" =~ ^[Nn]$ ]]; then
    echo "🔄 系统重启中..."
    sudo reboot
else
    echo "⚠️ 脚本执行完成，但未重启，请手动重启验证内核"
fi

echo "🎉 脚本执行完成！"
