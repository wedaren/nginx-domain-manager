# 安装和配置指南 📖

## 📦 系统依赖

### Ubuntu/Debian 系统
```bash
# 更新软件包列表
sudo apt update

# 安装nginx
sudo apt install -y nginx

# 安装SSL证书工具
sudo apt install -y certbot python3-certbot-nginx

# 安装常用工具
sudo apt install -y curl wget git
```

## 🚀 快速安装

### 1. 克隆项目
```bash
cd /home/admin
git clone <repository-url> nginx-domain-manager
cd nginx-domain-manager
```

### 2. 设置执行权限
```bash
chmod +x add-subdomain.sh
```

### 3. 运行第一次配置
```bash
sudo ./add-subdomain.sh
```

## ⚙️ nginx基础配置

### 1. nginx主配置优化
编辑 `/etc/nginx/nginx.conf`：

```nginx
user www-data;
worker_processes auto;
worker_connections 1024;

http {
    # 基础设置
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 30;
    types_hash_max_size 2048;
    client_max_body_size 20M;
    
    # 隐藏nginx版本
    server_tokens off;
    
    # 压缩设置
    gzip on;
    gzip_vary on;
    gzip_types
        text/plain
        text/css
        text/javascript
        application/javascript
        application/json
        application/xml;
    
    # 包含站点配置
    include /etc/nginx/sites-enabled/*;
}
```

### 2. 创建默认安全配置
创建 `/etc/nginx/snippets/security.conf`：

```nginx
# 安全头部
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

# 禁止访问隐藏文件
location ~ /\.(?!well-known) {
    deny all;
}
```

## 🔐 SSL证书配置

### 自动配置Let's Encrypt
```bash
# 为域名申请证书
sudo certbot --nginx -d example.com

# 测试自动续期
sudo certbot renew --dry-run

# 设置自动续期cron任务
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 手动SSL证书配置
如果使用自有证书，请确保：
1. 证书文件放在 `/etc/ssl/certs/`
2. 私钥文件放在 `/etc/ssl/private/`
3. 设置正确的文件权限：
```bash
sudo chmod 644 /etc/ssl/certs/your-cert.pem
sudo chmod 600 /etc/ssl/private/your-key.key
```

## 🔧 PHP环境配置

如需支持PHP网站，安装PHP-FPM：

```bash
# 安装PHP和扩展
sudo apt install -y php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip

# 优化PHP-FPM配置
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
```

推荐的PHP-FPM配置：
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

## 🛡️ 防火墙配置

```bash
# 安装ufw防火墙
sudo apt install -y ufw

# 配置防火墙规则
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'

# 启用防火墙
sudo ufw enable
```

## 📊 监控和日志

### 日志文件位置
- nginx访问日志: `/var/log/nginx/access.log`
- nginx错误日志: `/var/log/nginx/error.log`
- PHP-FPM日志: `/var/log/php8.1-fpm.log`

### 日志轮转配置
编辑 `/etc/logrotate.d/nginx`：
```
/var/log/nginx/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data adm
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

## ✅ 验证安装

### 1. 检查nginx状态
```bash
sudo systemctl status nginx
sudo nginx -t
```

### 2. 测试基本功能
```bash
curl -I http://localhost
```

### 3. 检查SSL配置
```bash
sudo certbot certificates
```

## 🚨 常见问题

### nginx启动失败
```bash
# 检查配置语法
sudo nginx -t

# 查看错误日志
sudo journalctl -u nginx -f

# 检查端口占用
sudo ss -tlnp | grep :80
```

### 权限问题
```bash
# 修复文件权限
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/
```

---
*安装完成后，请阅读 README.md 了解使用方法*
