# Docker镜像加速器命令行使用方法（无需重启Docker）

## 方法一：使用 --registry-mirror 参数（临时使用）

在拉取镜像时直接指定镜像源，无需修改配置文件或重启Docker：

```bash
# 基本语法：将 docker.io 替换为镜像源地址
docker pull 镜像源地址/library/镜像名:标签

# 示例：拉取nginx镜像
docker pull docker.m.daocloud.io/library/nginx:alpine
docker pull docker.1panel.live/library/nginx:alpine
docker pull hub.rat.dev/library/nginx:alpine

# 拉取官方镜像（library命名空间）
docker pull docker.m.daocloud.io/library/redis:latest
docker pull docker.m.daocloud.io/library/mysql:8.0
docker pull docker.m.daocloud.io/library/postgres:15

# 拉取用户镜像（非library命名空间）
docker pull docker.m.daocloud.io/bitnami/nginx:latest
docker pull docker.m.daocloud.io/linuxserver/plex:latest
```

---

## 方法二：使用完整镜像路径

直接使用镜像源的完整路径拉取：

```bash
# DaoCloud镜像源
docker pull docker.m.daocloud.io/library/nginx:alpine

# 1Panel镜像源
docker pull docker.1panel.live/library/nginx:alpine

# Rat.dev镜像源
docker pull hub.rat.dev/library/nginx:alpine

# 腾讯云镜像源
docker pull mirror.ccs.tencentyun.com/library/nginx:alpine
```

---

## 方法三：使用 docker tag 重命名（推荐）

拉取后重新打标签，方便后续使用：

```bash
# 1. 从镜像源拉取
docker pull docker.m.daocloud.io/library/nginx:alpine

# 2. 重新打标签为原始名称
docker tag docker.m.daocloud.io/library/nginx:alpine nginx:alpine

# 3. 删除带镜像源前缀的标签（可选）
docker rmi docker.m.daocloud.io/library/nginx:alpine

# 现在可以直接使用 nginx:alpine 了
docker run -d nginx:alpine
```

---

## 方法四：创建便捷脚本

创建一个脚本自动处理镜像拉取和重命名：

### Bash脚本（Linux/Mac/NAS）

创建文件 `docker-pull.sh`：

```bash
#!/bin/bash

# Docker镜像加速拉取脚本
# 使用方法: ./docker-pull.sh nginx:alpine

# 镜像源列表（按优先级排序）
MIRRORS=(
    "docker.m.daocloud.io"
    "docker.1panel.live"
    "hub.rat.dev"
    "dhub.kubesre.xyz"
    "docker.chenby.cn"
    "mirror.ccs.tencentyun.com"
)

# 获取要拉取的镜像名称
IMAGE=$1

if [ -z "$IMAGE" ]; then
    echo "使用方法: $0 <镜像名称:标签>"
    echo "示例: $0 nginx:alpine"
    exit 1
fi

# 解析镜像名称
if [[ $IMAGE == *"/"* ]]; then
    # 包含命名空间，如 bitnami/nginx:latest
    IMAGE_PATH=$IMAGE
else
    # 官方镜像，添加library前缀
    IMAGE_PATH="library/$IMAGE"
fi

# 尝试从镜像源拉取
SUCCESS=0
for MIRROR in "${MIRRORS[@]}"; do
    echo "尝试从 $MIRROR 拉取..."
    MIRROR_IMAGE="$MIRROR/$IMAGE_PATH"
    
    if docker pull "$MIRROR_IMAGE"; then
        echo "✓ 成功从 $MIRROR 拉取镜像"
        
        # 重新打标签为原始名称
        docker tag "$MIRROR_IMAGE" "$IMAGE"
        echo "✓ 已重命名为 $IMAGE"
        
        # 删除带镜像源前缀的标签
        docker rmi "$MIRROR_IMAGE" > /dev/null 2>&1
        
        SUCCESS=1
        break
    else
        echo "✗ 从 $MIRROR 拉取失败，尝试下一个..."
    fi
done

if [ $SUCCESS -eq 0 ]; then
    echo "✗ 所有镜像源都失败，尝试从官方源拉取..."
    docker pull "$IMAGE"
fi
```

使用方法：

```bash
# 添加执行权限
chmod +x docker-pull.sh

# 拉取镜像
./docker-pull.sh nginx:alpine
./docker-pull.sh redis:latest
./docker-pull.sh mysql:8.0
./docker-pull.sh bitnami/nginx:latest
```

### Windows批处理脚本

创建文件 `docker-pull.bat`：

```batch
@echo off
setlocal enabledelayedexpansion

REM Docker镜像加速拉取脚本
REM 使用方法: docker-pull.bat nginx:alpine

set IMAGE=%1
if "%IMAGE%"=="" (
    echo 使用方法: %0 镜像名称:标签
    echo 示例: %0 nginx:alpine
    exit /b 1
)

REM 镜像源列表
set MIRRORS=docker.m.daocloud.io docker.1panel.live hub.rat.dev dhub.kubesre.xyz

REM 检查是否包含命名空间
echo %IMAGE% | findstr /C:"/" >nul
if errorlevel 1 (
    set IMAGE_PATH=library/%IMAGE%
) else (
    set IMAGE_PATH=%IMAGE%
)

REM 尝试从镜像源拉取
for %%M in (%MIRRORS%) do (
    echo 尝试从 %%M 拉取...
    set MIRROR_IMAGE=%%M/%IMAGE_PATH%
    
    docker pull !MIRROR_IMAGE!
    if !errorlevel! equ 0 (
        echo 成功从 %%M 拉取镜像
        docker tag !MIRROR_IMAGE! %IMAGE%
        echo 已重命名为 %IMAGE%
        docker rmi !MIRROR_IMAGE! >nul 2>&1
        goto :success
    ) else (
        echo 从 %%M 拉取失败，尝试下一个...
    )
)

echo 所有镜像源都失败，尝试从官方源拉取...
docker pull %IMAGE%

:success
endlocal
```

---

## 方法五：使用 docker-compose 指定镜像源

在 `docker-compose.yml` 中直接使用镜像源地址：

```yaml
version: '3'
services:
  nginx:
    image: docker.m.daocloud.io/library/nginx:alpine
    ports:
      - "80:80"
  
  redis:
    image: docker.1panel.live/library/redis:latest
    ports:
      - "6379:6379"
  
  mysql:
    image: hub.rat.dev/library/mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
    ports:
      - "3306:3306"
```

---

## 方法六：使用环境变量（某些工具支持）

```bash
# 设置环境变量
export DOCKER_REGISTRY_MIRROR="docker.m.daocloud.io"

# 某些Docker工具会读取这个变量
# 注意：原生Docker不支持此方式，但某些第三方工具支持
```

---

## 常用镜像拉取示例

### 官方镜像（library命名空间）

```bash
# Nginx
docker pull docker.m.daocloud.io/library/nginx:alpine
docker tag docker.m.daocloud.io/library/nginx:alpine nginx:alpine

# Redis
docker pull docker.m.daocloud.io/library/redis:latest
docker tag docker.m.daocloud.io/library/redis:latest redis:latest

# MySQL
docker pull docker.m.daocloud.io/library/mysql:8.0
docker tag docker.m.daocloud.io/library/mysql:8.0 mysql:8.0

# PostgreSQL
docker pull docker.m.daocloud.io/library/postgres:15
docker tag docker.m.daocloud.io/library/postgres:15 postgres:15

# Node.js
docker pull docker.m.daocloud.io/library/node:18-alpine
docker tag docker.m.daocloud.io/library/node:18-alpine node:18-alpine

# Python
docker pull docker.m.daocloud.io/library/python:3.11-slim
docker tag docker.m.daocloud.io/library/python:3.11-slim python:3.11-slim
```

### 第三方镜像

```bash
# Bitnami镜像
docker pull docker.m.daocloud.io/bitnami/nginx:latest
docker tag docker.m.daocloud.io/bitnami/nginx:latest bitnami/nginx:latest

# LinuxServer镜像
docker pull docker.m.daocloud.io/linuxserver/plex:latest
docker tag docker.m.daocloud.io/linuxserver/plex:latest linuxserver/plex:latest
```

---

## 快速命令别名（推荐）

在 `~/.bashrc` 或 `~/.zshrc` 中添加别名：

```bash
# Docker镜像加速拉取别名
alias dpull='function _dpull(){ docker pull docker.m.daocloud.io/library/$1 && docker tag docker.m.daocloud.io/library/$1 $1 && docker rmi docker.m.daocloud.io/library/$1; }; _dpull'

# 使用方法
dpull nginx:alpine
dpull redis:latest
```

或者更智能的版本：

```bash
# 智能Docker拉取（自动处理命名空间）
alias dpull='function _dpull(){ 
    if [[ $1 == *"/"* ]]; then 
        docker pull docker.m.daocloud.io/$1 && docker tag docker.m.daocloud.io/$1 $1 && docker rmi docker.m.daocloud.io/$1
    else 
        docker pull docker.m.daocloud.io/library/$1 && docker tag docker.m.daocloud.io/library/$1 $1 && docker rmi docker.m.daocloud.io/library/$1
    fi
}; _dpull'

# 使用方法
dpull nginx:alpine              # 官方镜像
dpull bitnami/nginx:latest      # 第三方镜像
```

---

## 推荐的镜像源（按速度和稳定性排序）

```bash
# 1. DaoCloud（推荐，稳定）
docker.m.daocloud.io

# 2. 腾讯云（推荐，国内大厂）
mirror.ccs.tencentyun.com

# 3. OpenAtom（推荐，开放原子开源基金会）
atomhub.openatom.cn

# 4. 1Panel（稳定）
docker.1panel.live

# 5. Rat.dev（速度快）
hub.rat.dev

# 6. Kubesre（稳定）
dhub.kubesre.xyz

# 7. Chenby（备用）
docker.chenby.cn
```

---

## 验证镜像是否拉取成功

```bash
# 查看本地镜像列表
docker images

# 查看特定镜像
docker images nginx

# 运行测试
docker run --rm nginx:alpine nginx -v
```

---

## 注意事项

1. **命名空间规则**：
   - 官方镜像需要添加 `library/` 前缀
   - 第三方镜像直接使用原路径

2. **标签重命名**：
   - 拉取后建议重新打标签，方便后续使用
   - 可以删除带镜像源前缀的标签节省空间

3. **镜像源选择**：
   - 优先使用官方和大厂镜像源
   - 如果一个源失败，尝试其他源
   - 定期检查镜像源是否可用

4. **安全性**：
   - 只使用可信的镜像源
   - 拉取后验证镜像完整性

---

## 相关文件

- [`docker_mirrors.txt`](docker_mirrors.txt) - 最新的Docker镜像源列表
- [`NAS_Docker_Mirror_Setup.md`](NAS_Docker_Mirror_Setup.md) - NAS系统配置指南
