# WSL Proxy Bridge

<p align="center">
  <strong>Use a Windows-hosted Mihomo/Clash proxy from WSL2—without changing Windows-wide proxy settings.</strong>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg"></a>
  <img alt="Shell" src="https://img.shields.io/badge/shell-Bash%20%7C%20Zsh-4EAA25">
  <img alt="Platform" src="https://img.shields.io/badge/platform-WSL2-0078D4">
</p>

[简体中文](#简体中文) · [English](#english)

## 简体中文

### 简介

**WSL Proxy Bridge** 是一组轻量级 Bash/Zsh 辅助脚本，让 WSL2 中的 Ubuntu、Kali Linux 等发行版按需使用 Windows 上运行的 Mihomo/Clash HTTP 或 Mixed 代理端口，同时保持 Windows 应用的网络设置不变。

安装后可通过几个简短命令管理代理：

| 命令 | 作用 |
| --- | --- |
| `pon` | 为当前 Shell 启用代理环境变量 |
| `poff` | 清除当前 Shell 的代理环境变量 |
| `pstatus` | 查看 Windows 主机地址、端口与启用状态 |
| `ptest` | 显式通过代理测试 Google HTTPS 连通性 |

项目默认采用**手动开关模式**，不会在每个新终端中强制启用代理。Windows 主机地址会根据 WSL 默认路由动态探测，也可以手动指定。

### 设计目标

- **Windows 保持原样：** 不修改 Windows 系统代理，不要求 Windows 应用一起走代理。
- **兼容 Bash 与 Zsh：** 适用于 Ubuntu 常见的 Bash，以及 Kali 常见的 Zsh。
- **简化日常操作：** 使用 `pon`、`poff`、`pstatus`、`ptest`。
- **动态发现网关：** 每次开启或测试代理时读取 WSL 默认路由；支持自定义主机地址和端口。
- **可撤销安装：** 修改 Shell 启动文件前创建备份，使用有标记的加载区块，方便升级和卸载。
- **依赖轻量：** 核心逻辑使用 Shell 和常见网络工具，不需要额外的守护进程。

### 工作原理

```text
Windows 应用 ───────────────────────────────> Windows 当前网络（不由本项目更改）

WSL2 Ubuntu / Kali
       │
       │ pon：设置 http_proxy / https_proxy / all_proxy
       ▼
Windows Mihomo / Clash HTTP 或 Mixed 代理端口
       │
       ▼
Mihomo 规则与节点 ──────────────────────────> 目标站点
```

本项目配置的是**应用层代理环境变量**。只有会读取这些变量的应用才会自动使用代理；它不是透明代理、VPN 或 TUN 全流量隧道。

### 前置条件

1. Windows 上的 Mihomo/Clash 代理核心正在运行。
2. Windows 代理监听端口支持 HTTP 代理请求（HTTP 端口或 Mixed Port）；默认示例端口为 `7890`。
3. WSL 发行版能够访问 Windows 主机的代理监听地址和端口。
4. 必要时在 Windows 防火墙中允许来自 WSL 虚拟网络的访问。

> **安全提醒：** 如果代理服务监听 `0.0.0.0` 或其他非回环地址，请检查访问控制与 Windows 防火墙。不要把没有适当访问控制的代理端口暴露给不可信局域网或公网。

### 安装

在每个需要配置的 WSL 发行版中分别执行一次（Ubuntu 与 Kali 的 Linux 用户目录彼此独立）。

```bash
git clone https://github.com/Kris-smile/wsl-proxy-bridge.git
cd wsl-proxy-bridge
bash install.sh
```

安装脚本根据登录 Shell 选择 `~/.bashrc` 或 `~/.zshrc`，也可显式指定：

```bash
bash install.sh bash  # Ubuntu / Bash
bash install.sh zsh   # Kali / Zsh
```

脚本会将代理函数安装到 `~/.config/wsl-proxy-bridge/proxy.sh`，并在对应启动文件追加带标记的加载区块。修改前会备份原文件。安装完成后，重新打开终端或执行：

```bash
source ~/.bashrc  # Bash
source ~/.zshrc   # Zsh
```

### 快速开始

```bash
pon
pstatus
ptest
curl -I https://github.com
git ls-remote https://github.com/git/git.git HEAD
poff
```

`ptest` 使用显式的 `curl --proxy` 请求，因此可帮助区分“Windows 代理链路不可用”和“当前 Shell 尚未启用环境变量”。能够访问 GitHub 并不代表所有站点都能访问，最终结果取决于 Mihomo 的规则、节点和目标站点。

### 自定义主机和端口

默认情况下，项目从 WSL 默认路由中获取可访问的 Windows 主机地址，并使用端口 `7890`。如果你的网络模式或代理端口不同，可在运行命令前设置：

```bash
export WSL_PROXY_HOST="172.18.144.1"  # 示例地址；请替换为实际可访问的地址
export WSL_PROXY_PORT="7890"
pon
```

不要盲目复制示例网关地址；应先在当前发行版中通过端口连通性测试确认。

### 可选：终端启动时自动启用

默认是手动模式。若希望每次启动交互式终端时自动启用代理，可在项目加载区块之后单独添加：

```bash
proxy_on
```

这种模式下，`poff` 只影响当前 Shell；新开终端时会再次开启。想恢复手动模式，删除这条单独的 `proxy_on` 行即可。

### 卸载

在安装过项目的每个 WSL 发行版中运行对应命令：

```bash
bash uninstall.sh bash  # 移除 Bash 加载区块
bash uninstall.sh zsh   # 移除 Zsh 加载区块
```

卸载脚本会在修改启动文件前备份它，并删除项目的加载区块和已安装脚本，不会主动删除其他自定义配置。

### 故障排查

请先阅读 [故障排查指南](docs/TROUBLESHOOTING.md)。最常用的检查命令：

```bash
WIN_HOST="$(ip route show default | awk 'NR == 1 {print $3; exit}')"
printf 'Windows host: %s\n' "$WIN_HOST"
nc -vz "$WIN_HOST" 7890
curl -v --connect-timeout 10 --proxy "http://$WIN_HOST:7890" -I https://www.google.com
```

### 范围与限制

- 代理环境变量只影响支持这些变量的应用，不会透明代理所有进程。
- `git@github.com:owner/repo.git` 使用 SSH；HTTP 代理变量不会自动代理 SSH。
- `sudo` 可能清理代理环境变量，APT 也可能需要独立配置。
- 不保证覆盖任意 TCP/UDP、DNS、ICMP 或原始套接字流量。
- 如果需要更广泛的网络层流量捕获，请评估在 WSL 内配置 TUN 的方案，而不是将本项目当作全流量 VPN。

## English

**WSL Proxy Bridge** provides lightweight Bash/Zsh helpers for WSL2 distributions such as Ubuntu and Kali Linux to use a Windows-hosted Mihomo/Clash HTTP or Mixed proxy without changing Windows-wide proxy settings.

After installation, run `pon` to enable proxy environment variables, `poff` to clear them, `pstatus` to inspect the setup, and `ptest` to test an explicit proxied HTTPS request. The Windows host address is detected from the WSL default route unless `WSL_PROXY_HOST` is supplied manually. The proxy port defaults to `7890` and can be overridden with `WSL_PROXY_PORT`.

The installer backs up the selected shell startup file and adds a marked loader block. Bash and Zsh are configured independently; there is no need to source one shell's startup file from the other.

**Scope:** This project configures application-level proxy environment variables. It is not a transparent tunnel. Applications must honor proxy variables; SSH, arbitrary UDP, DNS, ICMP, and raw-socket traffic are not automatically covered. Read the [troubleshooting guide](docs/TROUBLESHOOTING.md) and review your proxy listener's network exposure before use.

## License

Distributed under the MIT License. See [LICENSE](LICENSE).
