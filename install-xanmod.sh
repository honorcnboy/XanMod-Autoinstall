#!/usr/bin/env bash
set -e

echo "============================================"
echo " XanMod Kernel Installer (Safe Interactive)"
echo " 保留旧内核 | 支持 GRUB 回退"
echo "============================================"
echo

# ---------- 基础环境 ----------
apt update
apt install -y gnupg wget lsb-release

# ---------- 添加 XanMod 源 ----------
echo "[+] 添加 XanMod 官方仓库（apt-keyring 模式）"

KEYRING="/usr/share/keyrings/xanmod-archive-keyring.gpg"
KEY_TMP="/tmp/xanmod.gpg.key"

# 下载 GPG key
if ! wget -O "$KEY_TMP" https://dl.xanmod.org/gpg.key; then
    echo "❌ 无法下载 XanMod GPG key"
    exit 1
fi

if [ ! -s "$KEY_TMP" ]; then
    echo "❌ 下载的 GPG key 为空"
    exit 1
fi

# 转换为 keyring
if ! gpg --dearmor < "$KEY_TMP" > "$KEYRING"; then
    echo "❌ GPG key 无效"
    exit 1
fi

rm -f "$KEY_TMP"

# 写入 source.list（绑定 key）
echo "deb [signed-by=$KEYRING] http://deb.xanmod.org releases main" \
  > /etc/apt/sources.list.d/xanmod-kernel.list

# 更新索引
apt update

# ---------- 显示可用内核 ----------
echo
echo "[+] 可用 XanMod 内核："
apt search linux-xanmod | grep xanmod | grep amd64
echo

# ---------- 选择内核分支 ----------
ATTEMPT=0
while true; do
    if [ "$ATTEMPT" -ge 5 ]; then
        echo "❌ 连续输入错误 5 次，脚本退出"
        exit 1
    fi

    read -rp "选择内核分支 [M]AIN/[E]DGE/[L]TS/[R]T (默认 E): " IN
    IN=${IN^^}
    [ -z "$IN" ] && IN="E"

    case "$IN" in
        M) KERNEL_BRANCH="mainline"; break ;;
        E) KERNEL_BRANCH="edge";     break ;;
        L) KERNEL_BRANCH="lts";      break ;;
        R) KERNEL_BRANCH="rt";       break ;;
        *)
            ATTEMPT=$((ATTEMPT+1))
            echo "输入错误，请输入 M/E/L/R（$ATTEMPT/5）"
            ;;
    esac
done

echo "✔ 已选择分支：$KERNEL_BRANCH"
echo

# ---------- CPU 指令集检测 ----------
FLAGS=$(lscpu | grep Flags)

if echo "$FLAGS" | grep -qw avx2; then
    RECOMMEND=3
elif echo "$FLAGS" | grep -qw sse4_2; then
    RECOMMEND=2
else
    RECOMMEND=1
fi

echo "[+] CPU 架构检测：推荐 x64v$RECOMMEND"
read -rp "是否使用推荐版本？[Y/n]: " CONFIRM
CONFIRM=${CONFIRM,,}
[ -z "$CONFIRM" ] && CONFIRM="y"

# ---------- 手动选择架构 ----------
if [ "$CONFIRM" = "n" ]; then
    ATTEMPT=0
    while true; do
        if [ "$ATTEMPT" -ge 5 ]; then
            echo "❌ 连续输入错误 5 次，脚本退出"
            exit 1
        fi

        read -rp "选择架构版本 [1=x64v1 / 2=x64v2 / 3=x64v3]: " V
        case "$V" in
            1|2|3) RECOMMEND="$V"; break ;;
            *)
                ATTEMPT=$((ATTEMPT+1))
                echo "输入错误，请输入 1/2/3（$ATTEMPT/5）"
                ;;
        esac
    done
fi

ARCH="x64v$RECOMMEND"
echo "✔ 最终选择：$KERNEL_BRANCH + $ARCH"
echo

# ---------- 安装内核 ----------
echo "[+] 安装 XanMod 内核..."
apt install -y linux-xanmod-${KERNEL_BRANCH}-${ARCH}

echo
echo "[+] 当前 GRUB 中的 XanMod 内核："
grep xanmod /boot/grub/grub.cfg || true
echo

# ---------- 是否更新 GRUB ----------
read -rp "是否更新 GRUB 并设为默认启动 XanMod？[Y/n]: " GRUB_OK
GRUB_OK=${GRUB_OK,,}
[ -z "$GRUB_OK" ] && GRUB_OK="y"

if [ "$GRUB_OK" = "y" ]; then
    DEFAULT_ENTRY=$(grep "menuentry '.*xanmod" /boot/grub/grub.cfg \
        | head -n1 \
        | sed "s/menuentry '\(.*\)'.*/\1/")

    sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"$DEFAULT_ENTRY\"|" /etc/default/grub
    sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=5|" /etc/default/grub

    update-grub
    echo "✔ GRUB 已更新，默认启动："
    echo "  $DEFAULT_ENTRY"
else
    echo "⚠ 已跳过 GRUB 更新"
fi

echo

# ---------- 重启确认 ----------
read -rp "是否现在重启以启用新内核？[Y/n]: " REBOOT
REBOOT=${REBOOT,,}
[ -z "$REBOOT" ] && REBOOT="y"

if [ "$REBOOT" = "y" ]; then
    echo "系统即将重启..."
    reboot
else
    echo "已跳过重启，请稍后手动 reboot"
fi
