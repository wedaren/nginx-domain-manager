#!/bin/bash

# 为nginx添加新的二级域名网站配置

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== nginx二级域名配置助手 ===${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本需要 root 权限运行${NC}"
   exit 1
fi

# 获取用户输入
echo -e "${YELLOW}请输入要配置的二级域名 (例如: blog.wedaren.tech):${NC}"
read -p "域名: " DOMAIN

if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}域名不能为空${NC}"
    exit 1
fi

echo -e "${YELLOW}请选择网站类型:${NC}"
echo "1. 静态网站 (HTML/CSS/JS)"
echo "2. 反向代理 (转发到其他端口)"
echo "3. PHP网站 (需要PHP-FPM)"

read -p "选择 (1-3): " SITE_TYPE

case $SITE_TYPE in
    1)
        echo -e "${BLUE}配置静态网站...${NC}"
        WEBROOT="/var/www/$DOMAIN"
        mkdir -p "$WEBROOT"
        chown -R www-data:www-data "$WEBROOT"
        
        # 创建示例页面
        cat > "$WEBROOT/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>$DOMAIN</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>欢迎访问 $DOMAIN</h1>
    <p>这是一个静态网站示例。</p>
    <p>您可以编辑 $WEBROOT/index.html 来修改内容。</p>
</body>
</html>
EOF
        
        # nginx配置
        cat > "/etc/nginx/sites-available/$DOMAIN" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    root $WEBROOT;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}

# 注释掉的HTTPS配置 - 如需HTTPS请申请证书后启用
# server {
#     listen 443 ssl http2;
#     server_name $DOMAIN;
#     
#     ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
#     
#     root $WEBROOT;
#     index index.html index.htm;
#     
#     location / {
#         try_files \$uri \$uri/ =404;
#     }
# }
EOF
        echo -e "${GREEN}✅ 静态网站配置创建完成${NC}"
        echo -e "${YELLOW}网站根目录: $WEBROOT${NC}"
        ;;
        
    2)
        echo -e "${YELLOW}请输入后端服务端口 (例如: 3000):${NC}"
        read -p "端口: " BACKEND_PORT
        
        if [[ ! "$BACKEND_PORT" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}端口必须是数字${NC}"
            exit 1
        fi
        
        # nginx反向代理配置
        cat > "/etc/nginx/sites-available/$DOMAIN" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://127.0.0.1:$BACKEND_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# 注释掉的HTTPS配置 - 如需HTTPS请申请证书后启用
# server {
#     listen 443 ssl http2;
#     server_name $DOMAIN;
#     
#     ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
#     
#     location / {
#         proxy_pass http://127.0.0.1:$BACKEND_PORT;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto \$scheme;
#         
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade \$http_upgrade;
#         proxy_set_header Connection "upgrade";
#     }
# }
EOF
        echo -e "${GREEN}✅ 反向代理配置创建完成${NC}"
        echo -e "${YELLOW}代理目标: localhost:$BACKEND_PORT${NC}"
        ;;
        
    3)
        echo -e "${BLUE}配置PHP网站...${NC}"
        
        # 安装PHP-FPM
        apt update
        apt install -y php-fpm php-mysql php-curl php-gd php-mbstring
        
        WEBROOT="/var/www/$DOMAIN"
        mkdir -p "$WEBROOT"
        chown -R www-data:www-data "$WEBROOT"
        
        # 创建示例PHP页面
        cat > "$WEBROOT/index.php" << EOF
<?php
echo "<h1>欢迎访问 $DOMAIN</h1>";
echo "<p>PHP版本: " . PHP_VERSION . "</p>";
echo "<p>当前时间: " . date('Y-m-d H:i:s') . "</p>";
phpinfo();
?>
EOF
        
        # 获取PHP版本
        PHP_VERSION=$(php -v | head -1 | cut -d' ' -f2 | cut -d'.' -f1,2)
        
        # nginx配置
        cat > "/etc/nginx/sites-available/$DOMAIN" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # SSL证书 - 需要为此域名申请证书
    # ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # 临时使用自签名证书（仅用于测试）
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    root $WEBROOT;
    index index.php index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
        echo -e "${GREEN}✅ PHP网站配置创建完成${NC}"
        echo -e "${YELLOW}网站根目录: $WEBROOT${NC}"
        ;;
        
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

# 启用网站配置
echo -e "${YELLOW}启用网站配置...${NC}"
ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/"

# 测试nginx配置
echo -e "${YELLOW}测试nginx配置...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    # 重载nginx
    systemctl reload nginx
    echo -e "${GREEN}✅ nginx配置重载成功${NC}"
    
    echo ""
    echo -e "${GREEN}=== $DOMAIN 配置完成！ ===${NC}"
    echo -e "${YELLOW}重要提醒:${NC}"
    echo "1. 当前使用临时SSL证书，仅用于测试"
    echo "2. 生产环境请申请正式SSL证书："
    echo "   sudo certbot --nginx -d $DOMAIN"
    echo ""
    echo -e "${YELLOW}测试访问:${NC}"
    echo "HTTP: http://$DOMAIN (会重定向到HTTPS)"
    echo "HTTPS: https://$DOMAIN (临时证书，浏览器会警告)"
    echo ""
    echo -e "${YELLOW}配置文件位置:${NC}"
    echo "nginx配置: /etc/nginx/sites-available/$DOMAIN"
    if [[ $SITE_TYPE -eq 1 || $SITE_TYPE -eq 3 ]]; then
        echo "网站根目录: $WEBROOT"
    fi
    
else
    echo -e "${RED}❌ nginx配置测试失败${NC}"
    echo "请检查配置文件: /etc/nginx/sites-available/$DOMAIN"
    exit 1
fi
