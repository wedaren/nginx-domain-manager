#!/bin/bash

# 配置 wxtest.wedaren.tech 转发到 http://100.110.94.77:3000/

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== 配置 wxtest.wedaren.tech 反向代理 ===${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本需要 root 权限运行${NC}"
   exit 1
fi

# 固定配置参数
DOMAIN="wxtest.wedaren.tech"
BACKEND_HOST="100.110.94.77"
BACKEND_PORT="3000"

echo -e "${BLUE}配置信息:${NC}"
echo "域名: $DOMAIN"
echo "后端服务: http://$BACKEND_HOST:$BACKEND_PORT/"

# 创建nginx反向代理配置
echo -e "${YELLOW}创建nginx配置...${NC}"

cat > "/etc/nginx/sites-available/$DOMAIN" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://$BACKEND_HOST:$BACKEND_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 缓冲设置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # 错误处理
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    }
    
    # 健康检查端点
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# 启用网站配置
echo -e "${YELLOW}启用网站配置...${NC}"
ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/"

# 检查后端服务是否可达
echo -e "${YELLOW}检查后端服务连接...${NC}"
if curl -s --connect-timeout 5 "http://$BACKEND_HOST:$BACKEND_PORT/" > /dev/null; then
    echo -e "${GREEN}✅ 后端服务连接正常${NC}"
else
    echo -e "${YELLOW}⚠️  无法连接到后端服务 http://$BACKEND_HOST:$BACKEND_PORT/${NC}"
    echo -e "${YELLOW}请确认：${NC}"
    echo "1. 后端服务已启动"
    echo "2. 防火墙允许访问端口 $BACKEND_PORT"
    echo "3. 网络连接正常"
    echo ""
    echo -e "${YELLOW}继续配置nginx...${NC}"
fi

# 测试nginx配置
echo -e "${YELLOW}测试nginx配置...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    # 重载nginx
    systemctl reload nginx
    echo -e "${GREEN}✅ nginx配置重载成功${NC}"
    
    # 自动申请SSL证书
    echo -e "${YELLOW}申请SSL证书并配置HTTPS...${NC}"
    if command -v certbot > /dev/null; then
        certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@wedaren.tech --redirect
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ SSL证书配置成功${NC}"
        else
            echo -e "${YELLOW}⚠️  SSL证书申请失败，但HTTP配置正常${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  certbot未安装，跳过SSL证书配置${NC}"
        echo -e "${YELLOW}手动安装certbot并配置SSL:${NC}"
        echo "sudo apt install certbot python3-certbot-nginx"
        echo "sudo certbot --nginx -d $DOMAIN"
    fi
    
    echo ""
    echo -e "${GREEN}=== $DOMAIN 反向代理配置完成！ ===${NC}"
    echo ""
    echo -e "${YELLOW}配置详情:${NC}"
    echo "域名: $DOMAIN"
    echo "转发目标: http://$BACKEND_HOST:$BACKEND_PORT/"
    echo "nginx配置文件: /etc/nginx/sites-available/$DOMAIN"
    echo ""
    echo -e "${YELLOW}测试访问:${NC}"
    echo "HTTP: http://$DOMAIN (自动重定向到HTTPS)"
    echo "HTTPS: https://$DOMAIN"
    echo "健康检查: https://$DOMAIN/health"
    echo ""
    echo -e "${YELLOW}检查状态:${NC}"
    echo "sudo systemctl status nginx"
    echo "curl -I https://$DOMAIN"
    
else
    echo -e "${RED}❌ nginx配置测试失败${NC}"
    echo "请检查配置文件: /etc/nginx/sites-available/$DOMAIN"
    exit 1
fi
