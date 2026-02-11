# Docker镜像加速拉取 - 快速使用指南

## 本地文件使用方法

### 方法1: 直接执行脚本（推荐）

```bash
# 1. 添加执行权限
chmod +x /volume1/docker/temp/docker_pull.sh

# 2. 使用默认镜像源
/volume1/docker/temp/docker_pull.sh openclaw:latest

# 3. 使用自定义镜像源文件
/volume1/docker/temp/docker_pull.sh openclaw:latest /volume1/docker/temp/docker_mirrors.txt
```

### 方法2: 使用bash执行

```bash
# 使用默认镜像源
bash /volume1/docker/temp/docker_pull.sh openclaw:latest

# 使用自定义镜像源文件
bash /volume1/docker/temp/docker_pull.sh openclaw:latest /volume1/docker/temp/docker_mirrors.txt
```

### 方法3: 在当前目录执行

```bash
# 进入脚本目录
cd /volume1/docker/temp

# 添加执行权限
chmod +x docker_pull.sh

# 执行
./docker_pull.sh openclaw:latest
./docker_pull.sh openclaw:latest ./docker_mirrors.txt
```

---

## 远程URL使用方法

只有当脚本托管在网络服务器上时才使用curl：

```bash
# 从GitHub或其他服务器下载并执行
bash -c "$(curl -sSLf https://raw.githubusercontent.com/user/repo/main/docker_pull.sh)" -s openclaw:latest

# 从自己的服务器
bash -c "$(curl -sSLf https://your-domain.com/docker_pull.sh)" -s openclaw:latest
```

---

## 群晖NAS专用快速命令

### 一次性使用（推荐）

```bash
# 进入脚本目录并执行
cd /volume1/docker/temp && bash docker_pull.sh openclaw:latest docker_mirrors.txt
```

### 创建全局命令别名

```bash
# 1. 编辑.bashrc或.profile
vi ~/.bashrc

# 2. 添加以下内容
alias dpull='/volume1/docker/temp/docker_pull.sh'

# 3. 重新加载配置
source ~/.bashrc

# 4. 现在可以在任何目录使用
dpull openclaw:latest
dpull nginx:alpine /volume1/docker/temp/docker_mirrors.txt
```

### 创建软链接（系统级命令）

```bash
# 创建软链接到系统路径
sudo ln -s /volume1/docker/temp/docker_pull.sh /usr/local/bin/docker-pull

# 现在可以全局使用
docker-pull openclaw:latest
docker-pull nginx:alpine /volume1/docker/temp/docker_mirrors.txt
```

---

## 针对你的情况

你想拉取 `openclaw:latest` 镜像，使用以下命令：

```bash
# 方法1: 直接执行（最简单）
bash /volume1/docker/temp/docker_pull.sh openclaw:latest /volume1/docker/temp/docker_mirrors.txt

# 方法2: 添加执行权限后运行
chmod +x /volume1/docker/temp/docker_pull.sh
/volume1/docker/temp/docker_pull.sh openclaw:latest /volume1/docker/temp/docker_mirrors.txt

# 方法3: 在目录内执行
cd /volume1/docker/temp
bash docker_pull.sh openclaw:latest docker_mirrors.txt
```

---

## 常见错误说明

### ❌ 错误用法
```bash
# curl不能读取本地文件
bash -c "$(curl -sSLf /volume1/docker/temp/docker_pull.sh)" -s openclaw:latest
```

### ✅ 正确用法
```bash
# 本地文件直接用bash执行
bash /volume1/docker/temp/docker_pull.sh openclaw:latest /volume1/docker/temp/docker_mirrors.txt
```

---

## 验证脚本是否正常

```bash
# 检查脚本是否存在
ls -lh /volume1/docker/temp/docker_pull.sh

# 查看脚本内容（前几行）
head -20 /volume1/docker/temp/docker_pull.sh

# 测试脚本语法
bash -n /volume1/docker/temp/docker_pull.sh

# 查看帮助信息
bash /volume1/docker/temp/docker_pull.sh --help
```

---

## 完整示例流程

```bash
# 1. 进入目录
cd /volume1/docker/temp

# 2. 确认文件存在
ls -lh docker_pull.sh docker_mirrors.txt

# 3. 添加执行权限
chmod +x docker_pull.sh

# 4. 执行拉取
./docker_pull.sh openclaw:latest ./docker_mirrors.txt

# 5. 验证镜像
docker images openclaw
```

---

## 如果openclaw不是官方镜像

如果 `openclaw` 是第三方镜像（如 `username/openclaw`），请使用完整路径：

```bash
# 如果是 Docker Hub 用户镜像
./docker_pull.sh username/openclaw:latest

# 如果是其他仓库
./docker_pull.sh registry.example.com/openclaw:latest
```

---

## 手动使用镜像源拉取（不用脚本）

如果脚本有问题，可以手动拉取：

```bash
# 尝试不同的镜像源
docker pull docker.m.daocloud.io/library/openclaw:latest
docker pull docker.1panel.live/library/openclaw:latest
docker pull hub.rat.dev/library/openclaw:latest

# 如果是用户镜像（假设是 username/openclaw）
docker pull docker.m.daocloud.io/username/openclaw:latest

# 拉取成功后重命名
docker tag docker.m.daocloud.io/library/openclaw:latest openclaw:latest
docker rmi docker.m.daocloud.io/library/openclaw:latest
```

---

## 故障排除

### 问题1: 权限被拒绝
```bash
# 解决方法
chmod +x /volume1/docker/temp/docker_pull.sh
# 或使用sudo
sudo bash /volume1/docker/temp/docker_pull.sh openclaw:latest
```

### 问题2: 找不到镜像
```bash
# openclaw可能不是官方镜像，检查完整名称
docker search openclaw

# 使用完整路径
./docker_pull.sh 完整镜像名:latest
```

### 问题3: 脚本执行错误
```bash
# 检查脚本格式（可能是Windows换行符）
dos2unix /volume1/docker/temp/docker_pull.sh

# 或手动转换
sed -i 's/\r$//' /volume1/docker/temp/docker_pull.sh
```

---

## 推荐的工作流程

```bash
# 一键执行（复制粘贴即可）
cd /volume1/docker/temp && \
chmod +x docker_pull.sh && \
./docker_pull.sh openclaw:latest ./docker_mirrors.txt
```
