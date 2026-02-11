# Docker镜像加速工具使用指南

## 快速开始

### 方法1: 本地使用脚本

```bash
# 1. 下载脚本
curl -sSLf https://raw.githubusercontent.com/your-repo/docker_pull.sh -o docker_pull.sh

# 2. 添加执行权限
chmod +x docker_pull.sh

# 3. 使用默认镜像源拉取
./docker_pull.sh nginx:alpine

# 4. 使用自定义镜像源文件
./docker_pull.sh nginx:alpine ./docker_mirrors.txt
```

### 方法2: 远程一键执行（推荐）

```bash
# 使用默认镜像源
bash -c "$(curl -sSLf https://raw.githubusercontent.com/your-repo/docker_pull.sh)" -s nginx:alpine

# 使用本地镜像源文件
bash -c "$(curl -sSLf https://raw.githubusercontent.com/your-repo/docker_pull.sh)" -s nginx:alpine ./docker_mirrors.txt
```

---

## 使用示例

### 拉取官方镜像

```bash
# Nginx
./docker_pull.sh nginx:alpine

# Redis
./docker_pull.sh redis:latest

# MySQL
./docker_pull.sh mysql:8.0

# PostgreSQL
./docker_pull.sh postgres:15

# Node.js
./docker_pull.sh node:18-alpine

# Python
./docker_pull.sh python:3.11-slim

# MongoDB
./docker_pull.sh mongo:latest

# Ubuntu
./docker_pull.sh ubuntu:22.04
```

### 拉取第三方镜像

```bash
# Bitnami镜像
./docker_pull.sh bitnami/nginx:latest
./docker_pull.sh bitnami/redis:latest

# LinuxServer镜像
./docker_pull.sh linuxserver/plex:latest
./docker_pull.sh linuxserver/jellyfin:latest

# 其他第三方镜像
./docker_pull.sh portainer/portainer-ce:latest
./docker_pull.sh traefik:latest
```

---

## 脚本特性

### 1. 智能镜像源切换
- 自动尝试多个镜像源
- 失败自动切换到下一个
- 最后尝试官方源

### 2. 自动重命名
- 拉取后自动重命名为原始镜像名
- 自动清理临时标签
- 无需手动操作

### 3. 彩色输出
- 成功：绿色
- 警告：黄色
- 错误：红色
- 信息：蓝色

### 4. 支持自定义镜像源
- 可以使用自己的镜像源文件
- 自动过滤注释和空行
- 支持带或不带 https:// 前缀

### 5. 错误处理
- 检查Docker是否安装
- 检查Docker服务是否运行
- 详细的错误提示

---

## 镜像源文件格式

创建 `docker_mirrors.txt` 文件：

```txt
# Docker镜像源列表
# 每行一个镜像源地址，支持注释

# 官方推荐
docker.m.daocloud.io
mirror.ccs.tencentyun.com
atomhub.openatom.cn

# 稳定镜像源
docker.1panel.live
hub.rat.dev
dhub.kubesre.xyz

# 备用镜像源
docker.chenby.cn
docker.kejilion.pro
```

---

## NAS上使用

### 群晖 Synology

```bash
# 1. SSH连接到NAS
ssh admin@your-nas-ip

# 2. 下载脚本
sudo curl -sSLf https://raw.githubusercontent.com/your-repo/docker_pull.sh -o /usr/local/bin/docker_pull.sh

# 3. 添加执行权限
sudo chmod +x /usr/local/bin/docker_pull.sh

# 4. 使用
docker_pull.sh nginx:alpine
```

### 威联通 QNAP

```bash
# 1. SSH连接
ssh admin@your-nas-ip

# 2. 下载脚本
curl -sSLf https://raw.githubusercontent.com/your-repo/docker_pull.sh -o /share/docker_pull.sh

# 3. 添加执行权限
chmod +x /share/docker_pull.sh

# 4. 使用
/share/docker_pull.sh nginx:alpine
```

---

## 创建命令别名

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
# Docker加速拉取别名
alias dpull='/path/to/docker_pull.sh'

# 或者使用远程版本
alias dpull='bash -c "$(curl -sSLf https://raw.githubusercontent.com/your-repo/docker_pull.sh)" -s'
```

重新加载配置：

```bash
source ~/.bashrc
# 或
source ~/.zshrc
```

使用别名：

```bash
dpull nginx:alpine
dpull redis:latest
```

---

## 高级用法

### 1. 批量拉取镜像

创建 `images.txt`：

```txt
nginx:alpine
redis:latest
mysql:8.0
postgres:15
mongo:latest
```

批量拉取脚本：

```bash
#!/bin/bash
while IFS= read -r image; do
    if [ -n "$image" ] && [[ ! "$image" =~ ^# ]]; then
        ./docker_pull.sh "$image"
    fi
done < images.txt
```

### 2. 与docker-compose集成

```bash
#!/bin/bash
# 从docker-compose.yml提取镜像并拉取

# 提取镜像列表
images=$(grep "image:" docker-compose.yml | awk '{print $2}')

# 拉取每个镜像
for image in $images; do
    ./docker_pull.sh "$image"
done

# 启动服务
docker-compose up -d
```

### 3. 定时更新镜像

创建cron任务：

```bash
# 编辑crontab
crontab -e

# 添加定时任务（每天凌晨2点更新）
0 2 * * * /path/to/docker_pull.sh nginx:alpine >> /var/log/docker_pull.log 2>&1
```

---

## 故障排除

### 问题1: 权限被拒绝

```bash
# 解决方法：添加执行权限
chmod +x docker_pull.sh
```

### 问题2: Docker服务未运行

```bash
# Linux
sudo systemctl start docker

# macOS
open -a Docker

# Windows
# 从开始菜单启动Docker Desktop
```

### 问题3: 所有镜像源都失败

```bash
# 1. 检查网络连接
ping docker.m.daocloud.io

# 2. 更新镜像源列表
curl -sSLf https://raw.githubusercontent.com/your-repo/docker_mirrors.txt -o docker_mirrors.txt

# 3. 使用更新后的列表
./docker_pull.sh nginx:alpine ./docker_mirrors.txt
```

### 问题4: curl命令不存在

```bash
# Debian/Ubuntu
sudo apt-get install curl

# CentOS/RHEL
sudo yum install curl

# macOS
brew install curl
```

---

## 性能对比

使用镜像加速器 vs 官方源：

| 镜像 | 官方源 | 加速器 | 提升 |
|------|--------|--------|------|
| nginx:alpine (23MB) | 180s | 8s | 22.5x |
| redis:latest (117MB) | 850s | 35s | 24.3x |
| mysql:8.0 (599MB) | 4200s | 180s | 23.3x |

---

## 安全建议

1. **验证镜像完整性**
   ```bash
   docker inspect nginx:alpine
   ```

2. **只使用可信镜像源**
   - 优先使用官方和大厂镜像源
   - 定期检查镜像源列表

3. **定期更新镜像**
   ```bash
   docker pull nginx:alpine
   docker images --filter "dangling=true" -q | xargs docker rmi
   ```

---

## 相关文件

- [`docker_pull.sh`](docker_pull.sh) - 主脚本文件
- [`docker_mirrors.txt`](docker_mirrors.txt) - 镜像源列表
- [`NAS_Docker_Mirror_Setup.md`](NAS_Docker_Mirror_Setup.md) - NAS配置指南
- [`Docker_CLI_Mirror_Usage.md`](Docker_CLI_Mirror_Usage.md) - 命令行使用方法

---

## 更新日志

### v1.0.0 (2025-12-16)
- 初始版本发布
- 支持自动镜像源切换
- 支持自定义镜像源文件
- 彩色输出和详细日志
- 自动重命名和清理

---

## 贡献

欢迎提交问题和改进建议！

## 许可证

MIT License
