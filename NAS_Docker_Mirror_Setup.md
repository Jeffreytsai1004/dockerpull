# NAS上配置Docker镜像加速器指南

## 一、群晖 Synology NAS

### 方法1: 通过Docker套件界面配置

1. 打开 **套件中心**，找到并打开 **Docker** 套件
2. 点击 **设置** → **注册表**
3. 在 **Docker Hub** 下方点击 **使用注册表镜像**
4. 添加镜像地址（从docker_mirrors.txt中选择），例如：
   ```
   https://docker.m.daocloud.io
   https://docker.1panel.live
   https://hub.rat.dev
   ```
5. 点击 **应用** 保存设置

### 方法2: 通过SSH修改配置文件

1. 启用SSH服务：**控制面板** → **终端机和SNMP** → 启用SSH服务
2. 使用SSH连接到NAS：
   ```bash
   ssh admin@你的NAS地址
   ```
3. 切换到root用户：
   ```bash
   sudo -i
   ```
4. 编辑Docker配置文件：
   ```bash
   vi /var/packages/Docker/etc/dockerd.json
   ```
5. 添加或修改registry-mirrors配置：
   ```json
   {
     "registry-mirrors": [
       "https://docker.m.daocloud.io",
       "https://docker.1panel.live",
       "https://hub.rat.dev",
       "https://dhub.kubesre.xyz"
     ]
   }
   ```
6. 保存文件后重启Docker服务：
   ```bash
   synoservicectl --restart pkgctl-Docker
   ```

---

## 二、威联通 QNAP NAS

### 方法1: 通过Container Station界面

1. 打开 **Container Station**
2. 点击右上角 **偏好设置** 图标
3. 选择 **Docker Hub注册表**
4. 添加镜像服务器地址
5. 点击 **应用** 保存

### 方法2: 通过SSH修改配置

1. 启用SSH：**控制台** → **网络与文件服务** → **Telnet/SSH** → 启用SSH
2. SSH连接到NAS：
   ```bash
   ssh admin@你的NAS地址
   ```
3. 编辑daemon.json：
   ```bash
   vi /etc/docker/daemon.json
   ```
4. 添加镜像配置：
   ```json
   {
     "registry-mirrors": [
       "https://docker.m.daocloud.io",
       "https://docker.1panel.live",
       "https://hub.rat.dev"
     ]
   }
   ```
5. 重启Docker服务：
   ```bash
   /etc/init.d/container-station.sh restart
   ```

---

## 三、TrueNAS / FreeNAS

1. 进入 **Shell** 或通过SSH连接
2. 创建或编辑daemon.json：
   ```bash
   mkdir -p /etc/docker
   vi /etc/docker/daemon.json
   ```
3. 添加配置：
   ```json
   {
     "registry-mirrors": [
       "https://docker.m.daocloud.io",
       "https://docker.1panel.live",
       "https://hub.rat.dev"
     ]
   }
   ```
4. 重启Docker服务：
   ```bash
   service docker restart
   ```

---

## 四、OpenMediaVault (OMV)

1. 通过SSH连接到OMV
2. 编辑Docker配置：
   ```bash
   sudo mkdir -p /etc/docker
   sudo nano /etc/docker/daemon.json
   ```
3. 添加镜像配置：
   ```json
   {
     "registry-mirrors": [
       "https://docker.m.daocloud.io",
       "https://docker.1panel.live",
       "https://hub.rat.dev"
     ]
   }
   ```
4. 重启Docker：
   ```bash
   sudo systemctl restart docker
   ```

---

## 五、Unraid

1. 进入 **Settings** → **Docker**
2. 找到 **Docker Hub URL** 设置
3. 在 **Registry Mirrors** 字段中添加镜像地址（用逗号分隔）：
   ```
   https://docker.m.daocloud.io,https://docker.1panel.live,https://hub.rat.dev
   ```
4. 点击 **Apply** 应用设置
5. Docker服务会自动重启

---

## 六、验证配置是否生效

配置完成后，可以通过以下命令验证：

```bash
docker info | grep -A 10 "Registry Mirrors"
```

或者：

```bash
docker info
```

在输出中查找 `Registry Mirrors` 部分，应该能看到你配置的镜像地址。

---

## 七、测试镜像加速效果

拉取一个测试镜像来验证加速效果：

```bash
# 拉取一个小镜像测试
docker pull hello-world

# 拉取一个常用镜像测试速度
docker pull nginx:alpine
```

如果速度明显提升，说明镜像加速器配置成功。

---

## 八、推荐的镜像源配置

根据稳定性和速度，推荐以下配置顺序：

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

---

## 九、常见问题

### Q1: 配置后仍然很慢？
- 尝试更换其他镜像源
- 检查网络连接
- 某些镜像源可能临时不可用，多配置几个备用

### Q2: 提示镜像源不可用？
- 镜像源可能已失效，参考docker_mirrors.txt中的最新列表
- 检查URL格式是否正确（需要https://前缀）

### Q3: 修改配置文件后无效？
- 确保重启了Docker服务
- 检查JSON格式是否正确（注意逗号和引号）
- 某些NAS系统需要重启整个系统才能生效

### Q4: 如何选择最快的镜像源？
可以使用以下脚本测试速度：

```bash
#!/bin/bash
mirrors=(
  "docker.m.daocloud.io"
  "docker.1panel.live"
  "hub.rat.dev"
  "dhub.kubesre.xyz"
)

for mirror in "${mirrors[@]}"; do
  echo "Testing $mirror..."
  time curl -I https://$mirror/v2/ 2>&1 | grep "HTTP"
done
```

---

## 十、注意事项

1. **定期更新镜像源列表**：某些镜像源可能会失效，建议定期检查docker_mirrors.txt获取最新列表
2. **配置多个镜像源**：Docker会按顺序尝试，如果第一个失败会自动使用下一个
3. **备份配置文件**：修改前建议备份原配置文件
4. **安全性**：只使用可信的镜像源，避免使用来源不明的镜像加速器

---

## 相关文件

- [`docker_mirrors.txt`](docker_mirrors.txt) - 最新的Docker镜像源列表
