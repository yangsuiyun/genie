#!/bin/bash

# SSL/HTTPS配置脚本
echo "🔐 Setting up SSL/HTTPS for Pomodoro Genie"
echo "=========================================="

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查域名参数
if [ -z "$1" ]; then
    log_error "请提供域名参数"
    echo "用法: $0 your-domain.com"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-admin@$DOMAIN}

log_info "域名: $DOMAIN"
log_info "邮箱: $EMAIL"

# 方案1: Let's Encrypt (推荐)
setup_letsencrypt() {
    log_info "设置Let's Encrypt SSL证书..."

    # 安装certbot
    if ! command -v certbot &> /dev/null; then
        log_info "安装certbot..."

        # Ubuntu/Debian
        if command -v apt &> /dev/null; then
            sudo apt update
            sudo apt install -y certbot python3-certbot-nginx
        # CentOS/RHEL
        elif command -v yum &> /dev/null; then
            sudo yum install -y certbot python3-certbot-nginx
        # macOS
        elif command -v brew &> /dev/null; then
            brew install certbot
        else
            log_error "无法自动安装certbot，请手动安装"
            return 1
        fi
    fi

    # 创建webroot目录
    sudo mkdir -p /var/www/certbot

    # 获取证书
    log_info "获取SSL证书..."
    sudo certbot certonly \
        --webroot \
        -w /var/www/certbot \
        -d $DOMAIN \
        -d www.$DOMAIN \
        --email $EMAIL \
        --agree-tos \
        --non-interactive

    if [ $? -eq 0 ]; then
        log_success "SSL证书获取成功"

        # 复制证书到项目目录
        mkdir -p ssl
        sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/
        sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/
        sudo chown $USER:$USER ssl/*.pem

        log_success "证书已复制到 ./ssl/ 目录"

        # 设置自动续期
        setup_auto_renewal

    else
        log_error "SSL证书获取失败"
        return 1
    fi
}

# 方案2: 自签名证书 (开发环境)
setup_self_signed() {
    log_info "创建自签名SSL证书 (仅用于开发环境)..."

    mkdir -p ssl

    # 生成私钥
    openssl genrsa -out ssl/privkey.pem 2048

    # 生成证书
    openssl req -new -x509 -key ssl/privkey.pem -out ssl/fullchain.pem -days 365 \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=$DOMAIN"

    log_success "自签名证书创建完成"
    log_warning "⚠️  浏览器会显示安全警告，仅用于开发环境"
}

# 设置证书自动续期
setup_auto_renewal() {
    log_info "设置证书自动续期..."

    # 创建续期脚本
    cat > renew-ssl.sh << 'EOF'
#!/bin/bash
# SSL证书自动续期脚本

# 续期证书
certbot renew --quiet

# 重新加载nginx
if [ -f "docker-compose.production.yml" ]; then
    docker-compose -f docker-compose.production.yml restart nginx
else
    systemctl reload nginx
fi

# 记录日志
echo "$(date): SSL证书续期检查完成" >> /var/log/ssl-renewal.log
EOF

    chmod +x renew-ssl.sh

    # 添加到crontab (每月1号执行)
    (crontab -l 2>/dev/null; echo "0 2 1 * * $(pwd)/renew-ssl.sh") | crontab -

    log_success "自动续期已设置 (每月1号执行)"
}

# 更新nginx配置
update_nginx_config() {
    log_info "更新nginx配置..."

    # 替换域名
    sed -i "s/pomodoro-genie.com/$DOMAIN/g" nginx.production.conf
    sed -i "s/www.pomodoro-genie.com/www.$DOMAIN/g" nginx.production.conf

    log_success "nginx配置已更新"
}

# 主菜单
echo ""
echo "选择SSL证书类型:"
echo "1. Let's Encrypt (免费，推荐用于生产环境)"
echo "2. 自签名证书 (开发环境)"
echo "3. 手动配置 (使用现有证书)"
echo ""
read -p "请选择 (1-3): " choice

case $choice in
    1)
        setup_letsencrypt
        update_nginx_config
        ;;
    2)
        setup_self_signed
        update_nginx_config
        ;;
    3)
        log_info "手动配置SSL证书:"
        echo "1. 将证书文件放入 ssl/ 目录:"
        echo "   - ssl/fullchain.pem (完整证书链)"
        echo "   - ssl/privkey.pem (私钥)"
        echo "2. 运行: bash deploy-production.sh"
        ;;
    *)
        log_error "无效选择"
        exit 1
        ;;
esac

# 显示下一步
if [ -f "ssl/fullchain.pem" ] && [ -f "ssl/privkey.pem" ]; then
    echo ""
    log_success "SSL配置完成！"
    echo ""
    echo "📋 下一步:"
    echo "1. 确保域名DNS指向服务器IP"
    echo "2. 运行部署脚本: bash deploy-production.sh"
    echo "3. 测试HTTPS访问: https://$DOMAIN"
    echo ""
    echo "🔧 证书管理:"
    echo "   检查证书: openssl x509 -in ssl/fullchain.pem -text -noout"
    echo "   续期证书: ./renew-ssl.sh"
    echo "   查看到期: openssl x509 -in ssl/fullchain.pem -noout -dates"
fi