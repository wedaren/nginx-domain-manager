#!/bin/bash

# 为nginx添加新的二级域名网站配置
# 改进版 - 移除自签名证书，只使用Let's Encrypt

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== nginx域名配置助手 (改进版) ===${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本需要 root 权限运行${NC}"
   exit 1
fi

# 检查nginx是否安装
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}nginx未安装，请先安装nginx${NC}"
    echo "sudo apt update && sudo apt install -y nginx"
    exit 1
fi

# 检查certbot是否安装
if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}certbot未安装，建议安装以支持SSL证书${NC}"
    echo "sudo apt install -y certbot python3-certbot-nginx"
fi

# 获取用户输入
echo -e "${YELLOW}请输入要配置的二级域名 (例如: blog.wedaren.tech):${NC}"
read -p "域名: " DOMAIN

if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}域名不能为空${NC}"
    exit 1
fi

# 检查域名格式
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    echo -e "${RED}域名格式不正确${NC}"
    exit 1
fi

# 检查配置文件是否已存在
if [[ -f "/etc/nginx/sites-available/$DOMAIN" ]]; then
    echo -e "${YELLOW}域名 $DOMAIN 的配置已存在${NC}"
    read -p "是否覆盖现有配置? (y/n): " OVERWRITE
    if [[ "$OVERWRITE" != "y" ]]; then
        echo "操作取消"
        exit 0
    fi
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
        cat > "$WEBROOT/index.html" << HTMLEOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$DOMAIN</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #007acc; padding-bottom: 10px; }
        .info { background: #e7f3ff; padding: 15px; border-left: 4px solid #007acc; margin: 20px 0; }
        .next-steps { background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 20px 0; }
        code { background: #f8f9fa; padding: 2px 4px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 欢迎访问 $DOMAIN</h1>
        <p>恭喜！您的静态网站已成功配置。</p>
        
        <div class="info">
            <strong>网站信息:</strong><br>
            域名: $DOMAIN<br>
            类型: 静态网站<br>
            根目录: $WEBROOT<br>
            创建时间: $(date '+%Y年%m月%d日 %H:%M:%S')
        </div>
        
        <div class="next-steps">
            <strong>下一步操作:</strong><br>
            1. 申请SSL证书: <code>sudo certbot --nginx -d $DOMAIN</code><br>
            2. 编辑网站内容: <code>sudo nano $WEBROOT/index.html</code><br>
            3. 上传文件到: <code>$WEBROOT/</code>
        </div>
        
        <h2>📁 文件管理</h2>
        <p>您可以将HTML、CSS、JavaScript等文件上传到网站根目录：</p>
        <ul>
            <li>HTML文件: <code>*.html</code></li>
            <li>样式文件: <code>css/</code></li>
            <li>脚本文件: <code>js/</code></li>
            <li>图片资源: <code>images/</code></li>
        </ul>
        
        <h2>🔐 SSL证书</h2>
        <p>当前使用HTTP访问，建议申请免费的Let's Encrypt SSL证书以启用HTTPS。</p>
    </div>
</body>
</html>
HTMLEOF
        
        # nginx配置 - 只配置HTTP，SSL由certbot自动配置
        cat > "/etc/nginx/sites-available/$DOMAIN" << EOF
# $DOMAIN 静态网站配置
server {
    listen 80;
    server_name $DOMAIN;
    
    root $WEBROOT;
    index index.html index.htm;
    
    # 安全设置
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # 静态文件缓存
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # 禁止访问隐藏文件
    location ~ /\.(?!well-known) {
        deny all;
    }
    
    # 健康检查
    location /health {
        access_log off;
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
