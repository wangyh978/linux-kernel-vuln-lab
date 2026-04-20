# Linux Kernel Vuln Lab (Minimal BusyBox)

一个**可复用的 Linux 内核漏洞研究与模拟框架**。

本框架致力于提供一个轻量级、标准化的内核调试环境，通过自动化脚本一键完成从内核源码下载、配置编译到根文件系统制作的全流程。
✨ 特性

本版本在原有框架基础上进行了多项改进与修复：

* **独立工作区输出**：生成的运行时环境完全独立，方便打包迁移。

* **弹性下载**：支持 `wget` 断点续传，避免网络波动导致的重新下载。

* **可视化进度**：下载过程显示实时进度条。

* **极致精简 BusyBox**：
  
  * 将默认配置从 `defconfig` 改为 `allnoconfig` + 最小化必要小程序 (Minimal Applets)。
  
  * 禁用了需要 `linux/kd.h` 头文件的控制台/键盘相关小程序，减少编译依赖和体积。

📂 目录结构
-------

    .
    ├── cases/          # 测试案例目录 (用于存放不同的漏洞场景或用户自定义文件)
    ├── config/         # 配置文件目录 (存放 Kernel 和 BusyBox 的默认配置模板)
    ├── scripts/        # 核心脚本目录 (包含所有构建阶段的子脚本)
    ├── .gitignore      # Git 忽略规则
    ├── Makefile        # 可选的 Make 辅助文件
    ├── lab.sh          # 主入口控制脚本
    └── README.md       # 项目说明文档

🛠️ 环境依赖
--------

在开始之前，请确保安装了以下依赖包：

### 必需依赖

```bash
sudo apt update
sudo apt install -y \
  build-essential bc bison flex libelf-dev libssl-dev dwarves pahole \
  cpio rsync curl xz-utils tar gzip bzip2 file \
  qemu-system-x86 qemu-utils gdb python3 wget
chmod -R +x .    #赋予执行权限 
```

### 可选依赖 (用于构建静态 BusyBox)

```bash
sudo apt install -y musl-tools
```

🚀 快速开始
-------

只需一条命令即可启动整个环境 (以内核版本 `6.6.30` 为例)：

```bash
./lab.sh up 6.6.30
```

该命令会自动执行：环境检查 -> 下载内核 -> 配置内核 -> 编译内核 -> 编译 BusyBox -> 制作 Rootfs -> 打包 Initramfs -> 启动 QEMU。
📖 详细用法

-------

`lab.sh` 是整个框架的控制中心，支持以下命令：

### 基本命令

* **检查环境**
  
      ./lab.sh check
  
    验证宿主机是否安装了所有必需的依赖工具。

* **一键启动 (Up)**
  
      ./lab.sh up <kernel-version> [case-name]
  
    执行全流程构建并直接启动 QEMU。这是最常用的命令。

* **运行 (Run)**
  
      ./lab.sh run <kernel-version> [case-name]
  
    逻辑与 `up` 完全相同，执行构建并启动。

### 分步构建命令

如果你想逐步控制构建过程或调试某一环节：

1. **获取内核源码**
   
   ```bash
   ./lab.sh fetch <kernel-version>
   ```

2. **配置内核**
   
   ```bash
    ./lab.sh config <kernel-version>
   ```

3. **编译内核**
   
   ```bash
    ./lab.sh kernel <kernel-version>
   ```

4. **编译 BusyBox**
   
   ```bash
   ./lab.sh busybox
   ```

5. **构建根文件系统 (Rootfs)**
   
   ```bash
   ./lab.sh rootfs <kernel-version> [case]
   ```

6. **打包 Initramfs**
   
   ```bash
   ./lab.sh initramfs <kernel-version> [case]
   ```

7. **创建独立工作区**
   
   ```bash
   ./lab.sh workspace <kernel-version> [case]
   ```

        这会在 `instances/` 目录下生成一个可移植的运行目录。

### 其他工具

* **创建新案例**(此项没有经过测试)
  
      ./lab.sh case <case-name>
  
    在 `cases/` 目录下创建一个新的测试案例模板。

* **清理构建产物**
  
      ./lab.sh clean <kernel-version>
  
    删除指定版本的内核构建文件、Rootfs 和实例目录，方便重新开始。

🐞 工作区使用
--------

当使用 `up`、`run` 或 `workspace` 命令后，框架会在 `instances/linux-<version>-<case>/` 下生成一个独立的工作区。

**在工作区内你可以：**

* **启动虚拟机：** `./start.sh`

* **启动并等待 GDB 连接 (调试模式)：** `./start-wait-gdb.sh`

* **连接 GDB 调试器：** `./gdb.sh`
