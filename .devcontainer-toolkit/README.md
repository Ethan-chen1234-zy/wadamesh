# OpenEdge Dev Container 工具包

## 设计思路

```
                    ┌─────────────────────────┐
                    │   base-embedded          │
                    │   cmake ninja git python │
                    └──────────┬──────────────┘
                               │
            ┌──────────────────┼──────────────────┐
            ▼                  ▼                  ▼
    ┌───────────────┐ ┌──────────────┐ ┌─────────────────┐
    │ platformio    │ │ arm-cortex-m │ │ nrf-connect     │
    │ +pio CLI      │ │ +ARM GCC 13  │ │ +nrfutil +west  │
    │ +ESP32/nRF52  │ │ +OpenOCD     │ │ +Zephyr deps    │
    └───────┬───────┘ └──────┬───────┘ └────────┬────────┘
            │                │                   │
     WisBlock              AI-OpenEdge          nRF54 项目
     Meshtastic            M55M1 固件
     MeshCore
```

**3 层继承**：公共工具在 base 里 → 各类型镜像加自己的工具链 → 工程只需 1 个 `devcontainer.json` 引用镜像。

---

## 快速开始

### 1. 构建镜像（一次性）

```powershell
cd .devcontainer-toolkit

# 构建全部 4 个镜像（约 10-15 分钟，取决于网速）
.\build-all.ps1

# 或只构建你需要的
.\build-all.ps1 -Only platformio
.\build-all.ps1 -Only arm-cortex-m
.\build-all.ps1 -Only nrf-connect
```

### 2. 给新工程创建环境

```powershell
# 一键从模板生成 .devcontainer/
.\new-project.ps1 -Path D:\Code\MyWisBlock   -Type platformio
.\new-project.ps1 -Path D:\Code\MeshCore     -Type platformio
.\new-project.ps1 -Path D:\Code\nRF54-FW     -Type nrf-connect
.\new-project.ps1 -Path D:\Code\M55M1-FW     -Type arm-embedded
```

### 3. 打开工程

```
VSCode 打开工程 → 左下角 >< → Reopen in Container → 就绪
```

---

## 三类工程对照

| 模板类型         | 适用项目                                          | 包含工具                               |
| ---------------- | ------------------------------------------------- | -------------------------------------- |
| `platformio`   | WisBlock (Arduino/PlatformIO)Meshtastic, MeshCore | PlatformIO CLI, ESP32 平台, nRF52 平台 |
| `arm-embedded` | CMSIS, ExecuTorch,裸机 ARM MCU 项目               | ARM GCC 13.2, CMake, OpenOCD           |
| `nrf-connect`  | nRF52/53/54 系列,Zephyr RTOS 项目                 | nrfutil, west, Zephyr 依赖             |

---

## 目录结构

```
.devcontainer-toolkit/
├── README.md                      ← 本文档
├── build-all.ps1                  ← 构建所有镜像
├── new-project.ps1                 ← 为新工程生成 .devcontainer/
├── docker/
│   ├── Dockerfile.base-embedded    ← 第 1 层：公共基础
│   ├── Dockerfile.platformio       ← 第 2 层：PlatformIO
│   ├── Dockerfile.arm-cortex-m     ← 第 2 层：ARM Cortex-M
│   └── Dockerfile.nrf-connect      ← 第 2 层：nRF Connect
└── templates/
    ├── platformio/
    │   └── .devcontainer/devcontainer.json
    ├── arm-embedded/
    │   └── .devcontainer/devcontainer.json
    └── nrf-connect/
        └── .devcontainer/devcontainer.json
```

---

## 日常使用

### 更新工具链

```powershell
# 编辑对应的 Dockerfile → 重新构建
.\build-all.ps1 -Only platformio
```

### 给有特殊需求的项目加额外依赖

不去改镜像，在项目自己的 `devcontainer.json` 里加 `postCreateCommand`：

```jsonc
{
  "image": "openedge/platformio:latest",
  // ...模板基础配置...
  "postCreateCommand": "pip install xxx && apt-get install -y yyy && echo '✅'"
}
```

### 共享到团队

```powershell
# 推送到 Docker Hub 或私有仓库
.\build-all.ps1 -Push -Registry registry.your-company.com/openedge
```

---

## 镜像体积参考

| 镜像              | 大小    |
| ----------------- | ------- |
| `base-embedded` | ~500 MB |
| `platformio`    | ~1.5 GB |
| `arm-cortex-m`  | ~1.2 GB |
| `nrf-connect`   | ~800 MB |

> 体积主要来自编译工具链。镜像层有缓存，同一台机器上 platformio 和 arm-cortex-m 共享 base 层，实际额外占用不大。

---

## FAQ

### Q: 为什么不用 Dev Container Features 而用自定义镜像？

A: Features 适合小工具；大型工具链（ARM GCC 13 几百 MB）放 Feature 里每次创建容器都要重新下载，太慢。预构建镜像秒开。

### Q: USB 烧录怎么弄？

A: 镜像加了 `--privileged`。Windows 上需要通过 WSL2 转发 USB — 用 `usbipd bind` + `usbipd attach`。

### Q: 多个工程同时打开怎么切换？

A: VSCode 多个窗口各自跑各自的容器，自动隔离，无需手动切换。
