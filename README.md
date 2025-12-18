1️⃣ **下载自动安装脚本**
```
wget https://raw.githubusercontent.com/honorcnboy/XanMod-Autoinstall/refs/heads/main/install-xanmod.sh
```

2️⃣ **给脚本添加执行权限**
```
chmod +x install-xanmod.sh
```

3️⃣ **执行脚本**
```
./install-xanmod.sh
```

⚠️ 脚本内包含 sudo 命令，因此执行时需要你的用户有 sudo 权限，并会提示输入密码。


4️⃣ **脚本运行过程**

- 系统会先更新、安装必要工具

- 添加 XanMod 仓库

- 显示可用内核类型，让你选择（MAIN/EDGE/LTS/RT）

- 检测 CPU 支持的版本，自动确认安装对应内核版本（x64v1/x64v2/x64v3）

- 自动安装对应 XanMod 内核

- 显示 GRUB 中可用内核，让你确认是否更新 GRUB 并设置默认启动

- 重启前让你确认是否立即重启系统

- 整个过程既有自动化，也保留了关键交互确认，保证安全。


5️⃣ **验证安装结果**

重启后登录系统

查看当前运行内核：
```
uname -r
```

:bulb:如果输出类似 6.5.3-xanmod1，说明新内核已经启动成功

旧内核仍在系统中，可在 GRUB 菜单中选择回退
