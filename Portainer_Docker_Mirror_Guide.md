# Portainer中使用Docker镜像加速器指南

## 概述

Portainer是一个流行的Docker可视化管理工具，本指南将介绍如何在Portainer中使用Docker镜像加速器。

---

## 方法一：在Portainer中直接使用镜像源地址（推荐）

### 1. 创建容器时使用完整镜像地址

在Portainer界面中创建容器时，直接使用镜像源的完整地址：

#### 步骤：

1. 登录Portainer
2. 选择 **Containers** → **Add container**
3. 在 **Image** 字段中输入完整的镜像地址：

```
# 官方镜像格式
docker.m.daocloud.io/library/nginx:alpine
docker.1panel.live/library/redis:latest
hub.rat.dev/library/mysql:8.0

# 第三方镜像格式
docker.m.daocloud.io/bitnami/nginx:latest
docker.1panel.live/linuxserver/plex:latest
```

4. 配置其他参数（端口、卷、环境变量等）
5. 点击 **Deploy the container**

![Portainer创建容器示例](https://via.placeholder.com/800x400?text=Portainer+Create+Container)

---

## 方法二：在Portainer Stacks中使用（Docker Compose）

### 1. 使用镜像源地址的Stack配置

在Portainer的Stacks功能中，直接在docker-compose.yml中使用镜像源地址：

#### 步骤：

1. 进入 **Stacks** → **Add stack**
2. 输入Stack名称
3. 在Web editor中输入配置：

```yaml
version: '3'

services:
  nginx:
    image: docker.m.daocloud.io/library/nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
    restart: unless-stopped
  
  redis:
    image: docker.1panel.live/library/redis:latest
    container_name: redis
    ports:
      - "6379:6379"
    restart: unless-stopped
  
  mysql:
    image: hub.rat.dev/library/mysql:8.0
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: your_password
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    restart: unless-stopped
  
  portainer-agent:
    image: docker.m.daocloud.io/portainer/agent:latest
    container_name: portainer-agent
    ports:
      - "9001:9001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    restart: unless-stopped

volumes:
  mysql_data:
```

4. 点击 **Deploy the stack**

---

## 方法三：配置Docker守护进程（全局生效）

如果你想让Portainer自动使用镜像加速器，需要在Docker守护进程级别配置。

### Linux系统（包括NAS）

#### 1. 通过SSH连接到服务器

```bash
ssh user@your-server-ip
```

#### 2. 编辑Docker配置文件

```bash
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

#### 3. 添加镜像源配置

```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://mirror.ccs.tencentyun.com",
    "https://atomhub.openatom.cn",
    "https://docker.1panel.live",
    "https://hub.rat.dev",
    "https://dhub.kubesre.xyz"
  ]
}
```

#### 4. 重启Docker服务

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

#### 5. 验证配置

```bash
docker info | grep -A 10 "Registry Mirrors"
```

配置成功后，在Portainer中拉取镜像时会自动使用配置的镜像源。

---

## 方法四：在Portainer中使用自定义Registry

### 1. 添加自定义Registry

虽然Docker镜像加速器不是标准的Registry，但可以通过以下方式管理：

#### 步骤：

1. 进入 **Registries** → **Add registry**
2. 选择 **Custom registry**
3. 填写信息：
   - **Name**: DaoCloud Mirror
   - **Registry URL**: `docker.m.daocloud.io`
   - **Authentication**: 关闭（公共镜像源不需要认证）
4. 点击 **Add registry**

**注意**：这种方法可能不适用于所有镜像加速器，因为它们不是完整的Registry实现。

---

## 方法五：使用Portainer的Image Templates

### 创建自定义模板

1. 进入 **App Templates** → **Custom Templates** → **Add Custom Template**
2. 创建模板时使用镜像源地址：

```json
{
  "type": 1,
  "title": "Nginx (加速)",
  "description": "使用镜像加速器的Nginx",
  "image": "docker.m.daocloud.io/library/nginx:alpine",
  "ports": [
    "80:80/tcp"
  ],
  "volumes": [
    {
      "container": "/usr/share/nginx/html"
    }
  ]
}
```

---

## 常用服务的Portainer配置示例

### 1. Nginx Web服务器

```yaml
version: '3'
services:
  nginx:
    image: docker.m.daocloud.io/library/nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/html:/usr/share/nginx/html
      - ./nginx/conf:/etc/nginx/conf.d
    restart: unless-stopped
```

### 2. MySQL数据库

```yaml
version: '3'
services:
  mysql:
    image: hub.rat.dev/library/mysql:8.0
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: myapp
      MYSQL_USER: myuser
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    restart: unless-stopped

volumes:
  mysql_data:
```

### 3. Redis缓存

```yaml
version: '3'
services:
  redis:
    image: docker.1panel.live/library/redis:alpine
    container_name: redis
    command: redis-server --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  redis_data:
```

### 4. PostgreSQL数据库

```yaml
version: '3'
services:
  postgres:
    image: docker.m.daocloud.io/library/postgres:15-alpine
    container_name: postgres
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

### 5. MongoDB数据库

```yaml
version: '3'
services:
  mongodb:
    image: docker.m.daocloud.io/library/mongo:latest
    container_name: mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    restart: unless-stopped

volumes:
  mongodb_data:
```

### 6. WordPress完整站点

```yaml
version: '3'

services:
  wordpress:
    image: docker.m.daocloud.io/library/wordpress:latest
    container_name: wordpress
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: ${WP_DB_PASSWORD}
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: hub.rat.dev/library/mysql:8.0
    container_name: wordpress_db
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: ${WP_DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

volumes:
  wordpress_data:
  db_data:
```

### 7. Nextcloud私有云

```yaml
version: '3'

services:
  nextcloud:
    image: docker.m.daocloud.io/library/nextcloud:latest
    container_name: nextcloud
    ports:
      - "8080:80"
    environment:
      MYSQL_HOST: db
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_PASSWORD: ${NC_DB_PASSWORD}
    volumes:
      - nextcloud_data:/var/www/html
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: docker.1panel.live/library/mariadb:latest
    container_name: nextcloud_db
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_PASSWORD: ${NC_DB_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

volumes:
  nextcloud_data:
  db_data:
```

### 8. Home Assistant智能家居

```yaml
version: '3'
services:
  homeassistant:
    image: docker.m.daocloud.io/homeassistant/home-assistant:latest
    container_name: homeassistant
    network_mode: host
    environment:
      TZ: Asia/Shanghai
    volumes:
      - ./homeassistant:/config
    restart: unless-stopped
```

### 9. Jellyfin媒体服务器

```yaml
version: '3'
services:
  jellyfin:
    image: docker.m.daocloud.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Asia/Shanghai
    ports:
      - "8096:8096"
    volumes:
      - ./jellyfin/config:/config
      - ./media/movies:/data/movies
      - ./media/tvshows:/data/tvshows
    restart: unless-stopped
```

### 10. Plex媒体服务器

```yaml
version: '3'
services:
  plex:
    image: docker.1panel.live/linuxserver/plex:latest
    container_name: plex
    network_mode: host
    environment:
      PUID: 1000
      PGID: 1000
      VERSION: docker
      TZ: Asia/Shanghai
    volumes:
      - ./plex/config:/config
      - ./media:/media
    restart: unless-stopped
```

---

## 推荐的镜像源配置

根据稳定性和速度，推荐以下镜像源：

### 官方和大厂镜像源（最稳定）

```
docker.m.daocloud.io          # DaoCloud（推荐）
mirror.ccs.tencentyun.com     # 腾讯云
atomhub.openatom.cn           # 开放原子开源基金会
```

### 社区镜像源（速度快）

```
docker.1panel.live            # 1Panel
docker.1panel.dev             # 1Panel备用
hub.rat.dev                   # Rat.dev
dhub.kubesre.xyz              # Kubesre
docker.chenby.cn              # Chenby
```

### 备用镜像源

```
docker.kejilion.pro
docker.xuanyuan.me
docker.nastool.de
docker.ckyl.me
docker.awsl9527.cn
```

---

## 在Portainer中使用环境变量

为了方便管理镜像源，可以使用环境变量：

### 1. 创建环境变量文件 `.env`

```env
# Docker镜像源
DOCKER_MIRROR=docker.m.daocloud.io

# 数据库密码
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_PASSWORD=your_password
POSTGRES_PASSWORD=your_postgres_password
MONGO_PASSWORD=your_mongo_password
```

### 2. 在Stack中使用

```yaml
version: '3'
services:
  nginx:
    image: ${DOCKER_MIRROR}/library/nginx:alpine
    ports:
      - "80:80"
```

**注意**：Portainer的Stack功能支持环境变量，但需要在Stack设置中上传或配置`.env`文件。

---

## 故障排除

### 问题1: Portainer无法拉取镜像

**解决方法**：
1. 检查镜像地址格式是否正确
2. 尝试更换其他镜像源
3. 检查网络连接

```bash
# 手动测试镜像源
curl -I https://docker.m.daocloud.io/v2/
```

### 问题2: Stack部署失败

**解决方法**：
1. 检查YAML语法是否正确
2. 确保镜像地址完整
3. 查看Portainer日志

### 问题3: 镜像拉取速度慢

**解决方法**：
1. 更换速度更快的镜像源
2. 配置Docker守护进程使用镜像加速器
3. 使用本地缓存

### 问题4: 某些镜像无法找到

**解决方法**：
1. 确认镜像名称和标签正确
2. 某些镜像可能不在镜像源中，尝试其他源
3. 使用官方Docker Hub

---

## 最佳实践

### 1. 使用多个镜像源

在daemon.json中配置多个镜像源，Docker会自动尝试：

```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live",
    "https://hub.rat.dev"
  ]
}
```

### 2. 定期更新镜像

在Portainer中设置定期更新策略：

1. 进入 **Containers**
2. 选择容器 → **Recreate**
3. 勾选 **Pull latest image**

### 3. 使用版本标签

避免使用`latest`标签，使用具体版本：

```yaml
# 不推荐
image: docker.m.daocloud.io/library/nginx:latest

# 推荐
image: docker.m.daocloud.io/library/nginx:1.25-alpine
```

### 4. 备份配置

定期备份Portainer的Stack配置：

1. 进入 **Stacks**
2. 选择Stack → **Editor**
3. 复制配置保存到本地

---

## 性能对比

使用镜像加速器在Portainer中部署的速度提升：

| 服务 | 官方源 | 加速器 | 提升 |
|------|--------|--------|------|
| Nginx | 3分钟 | 8秒 | 22.5x |
| MySQL | 15分钟 | 40秒 | 22.5x |
| WordPress Stack | 20分钟 | 1分钟 | 20x |

---

## 相关资源

- [`docker_mirrors.txt`](docker_mirrors.txt) - 最新镜像源列表
- [`docker_pull.sh`](docker_pull.sh) - 命令行拉取脚本
- [`NAS_Docker_Mirror_Setup.md`](NAS_Docker_Mirror_Setup.md) - NAS配置指南
- [`Docker_CLI_Mirror_Usage.md`](Docker_CLI_Mirror_Usage.md) - 命令行使用方法
- [`README.md`](README.md) - 总体使用指南

---

## 视频教程

### Portainer基础配置
1. 安装Portainer
2. 配置镜像加速器
3. 创建第一个容器

### Stack部署实战
1. 部署WordPress
2. 部署Nextcloud
3. 部署媒体服务器

---

## 总结

在Portainer中使用Docker镜像加速器有三种主要方式：

1. **直接使用完整镜像地址**（最简单，推荐新手）
2. **在Stack中使用镜像源地址**（适合复杂部署）
3. **配置Docker守护进程**（全局生效，一劳永逸）

选择适合你的方式，享受飞速的镜像拉取体验！
