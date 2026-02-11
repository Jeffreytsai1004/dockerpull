#!/bin/bash

# Docker镜像加速拉取脚本
# 使用方法: 
#   bash -c "$(curl -sSLf https://your-domain.com/docker_pull.sh)" -s 镜像名 [代理文件路径]
#   或本地使用: ./docker_pull.sh 镜像名 [代理文件路径]
# 
# 示例:
#   bash docker_pull.sh nginx:alpine
#   bash docker_pull.sh nginx:alpine ./docker_mirrors.txt
#   bash -c "$(curl -sSLf https://your-domain.com/docker_pull.sh)" -s nginx:alpine

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认镜像源列表（2025年12月最新）
DEFAULT_MIRRORS=(
    "docker.m.daocloud.io"
    "mirror.ccs.tencentyun.com"
    "atomhub.openatom.cn"
    "docker.1panel.live"
    "docker.1panel.dev"
    "hub.rat.dev"
    "dhub.kubesre.xyz"
    "docker.chenby.cn"
    "docker.kejilion.pro"
    "docker.xuanyuan.me"
    "docker.nastool.de"
    "docker.ckyl.me"
    "docker.awsl9527.cn"
    "docker.mrxn.net"
    "docker.anyhub.us.kg"
    "docker.wget.at"
)

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示使用帮助
show_help() {
    cat << EOF
Docker镜像加速拉取脚本

使用方法:
  $0 <镜像名> [代理文件路径]

参数说明:
  镜像名          - 必需，要拉取的Docker镜像（如: nginx:alpine）
  代理文件路径    - 可选，包含镜像源列表的文件路径

示例:
  # 使用默认镜像源
  $0 nginx:alpine
  
  # 使用自定义镜像源文件
  $0 nginx:alpine ./docker_mirrors.txt
  
  # 拉取第三方镜像
  $0 bitnami/nginx:latest
  
  # 远程执行
  bash -c "\$(curl -sSLf https://your-domain.com/docker_pull.sh)" -s nginx:alpine

支持的镜像格式:
  - 官方镜像: nginx:alpine, redis:latest, mysql:8.0
  - 第三方镜像: bitnami/nginx:latest, linuxserver/plex:latest

EOF
}

# 从文件加载镜像源
load_mirrors_from_file() {
    local file=$1
    local mirrors=()
    
    if [ ! -f "$file" ]; then
        print_error "镜像源文件不存在: $file"
        return 1
    fi
    
    print_info "从文件加载镜像源: $file"
    
    # 读取文件，过滤注释和空行
    while IFS= read -r line; do
        # 移除前后空格
        line=$(echo "$line" | xargs)
        
        # 跳过空行和注释行
        if [ -z "$line" ] || [[ "$line" =~ ^# ]]; then
            continue
        fi
        
        # 移除 https:// 或 http:// 前缀
        line=$(echo "$line" | sed 's|^https\?://||')
        
        mirrors+=("$line")
    done < "$file"
    
    if [ ${#mirrors[@]} -eq 0 ]; then
        print_warning "文件中没有找到有效的镜像源，使用默认列表"
        return 1
    fi
    
    print_success "成功加载 ${#mirrors[@]} 个镜像源"
    echo "${mirrors[@]}"
}

# 检测镜像源是否可用
test_mirror() {
    local mirror=$1
    local timeout=5
    
    # 测试镜像源连接
    if curl -sSf --connect-timeout $timeout "https://$mirror/v2/" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 拉取Docker镜像
pull_image() {
    local image=$1
    local mirrors=("${@:2}")
    
    # 解析镜像名称
    local image_name=$image
    local image_path=""
    
    # 检查是否包含命名空间
    if [[ $image_name == *"/"* ]]; then
        # 包含命名空间，如 bitnami/nginx:latest
        image_path=$image_name
    else
        # 官方镜像，添加library前缀
        image_path="library/$image_name"
    fi
    
    print_info "准备拉取镜像: $image_name"
    print_info "镜像路径: $image_path"
    print_info "可用镜像源数量: ${#mirrors[@]}"
    echo ""
    
    # 尝试从每个镜像源拉取
    local success=0
    local tried=0
    
    for mirror in "${mirrors[@]}"; do
        tried=$((tried + 1))
        print_info "[$tried/${#mirrors[@]}] 尝试镜像源: $mirror"
        
        # 构建完整镜像地址
        local mirror_image="$mirror/$image_path"
        
        # 尝试拉取
        if docker pull "$mirror_image" 2>&1; then
            print_success "成功从 $mirror 拉取镜像"
            echo ""
            
            # 重新打标签为原始名称
            print_info "重命名镜像: $mirror_image -> $image_name"
            if docker tag "$mirror_image" "$image_name"; then
                print_success "镜像已重命名为: $image_name"
                
                # 删除带镜像源前缀的标签
                print_info "清理临时标签..."
                docker rmi "$mirror_image" > /dev/null 2>&1 || true
                
                success=1
                break
            else
                print_error "重命名镜像失败"
            fi
        else
            print_warning "从 $mirror 拉取失败"
            echo ""
        fi
    done
    
    # 如果所有镜像源都失败，尝试官方源
    if [ $success -eq 0 ]; then
        print_warning "所有镜像源都失败，尝试从Docker官方源拉取..."
        echo ""
        
        if docker pull "$image_name"; then
            print_success "成功从官方源拉取镜像"
            success=1
        else
            print_error "从官方源拉取也失败了"
            return 1
        fi
    fi
    
    # 显示最终结果
    echo ""
    echo "=========================================="
    if [ $success -eq 1 ]; then
        print_success "镜像拉取完成: $image_name"
        echo ""
        print_info "验证镜像信息:"
        docker images "$image_name" | head -n 2
    else
        print_error "镜像拉取失败: $image_name"
        return 1
    fi
    echo "=========================================="
}

# 主函数
main() {
    # 检查参数
    if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        show_help
        exit 0
    fi
    
    local image=$1
    local mirror_file=$2
    local mirrors=()
    
    # 检查Docker是否安装
    if ! command -v docker &> /dev/null; then
        print_error "Docker未安装或不在PATH中"
        exit 1
    fi
    
    # 检查Docker是否运行
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker服务未运行，请先启动Docker"
        exit 1
    fi
    
    echo "=========================================="
    echo "  Docker镜像加速拉取工具"
    echo "=========================================="
    echo ""
    
    # 加载镜像源
    if [ -n "$mirror_file" ]; then
        # 从文件加载
        loaded_mirrors=$(load_mirrors_from_file "$mirror_file")
        if [ $? -eq 0 ]; then
            mirrors=($loaded_mirrors)
        else
            print_warning "使用默认镜像源列表"
            mirrors=("${DEFAULT_MIRRORS[@]}")
        fi
    else
        print_info "使用默认镜像源列表"
        mirrors=("${DEFAULT_MIRRORS[@]}")
    fi
    
    echo ""
    
    # 拉取镜像
    pull_image "$image" "${mirrors[@]}"
}

# 执行主函数
main "$@"
