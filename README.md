# Nginx 域名管理工具 🌐

一个用于快速配置nginx虚拟主机和管理多个域名的自动化工具。

## 🚀 功能特性

- **一键添加域名**: 快速创建新的nginx虚拟主机配置
- **多种网站类型**: 支持静态网站、反向代理和PHP应用
- **SSL证书管理**: 集成Let's Encrypt自动证书申请
- **智能配置**: 自动创建优化的nginx配置文件
- **安全加固**: 内置安全配置和最佳实践

## 📋 支持的网站类型

### 1. 静态网站 📄
- HTML/CSS/JS静态文件
- 自动创建网站根目录
- 生成示例页面

### 2. 反向代理 🔄
- 转发请求到后端应用
- 支持WebSocket连接
- 负载均衡支持

### 3. PHP网站 🐘
- 自动安装PHP-FPM
- 优化的PHP配置
- 支持MySQL等数据库

## 🛠️ 系统要求

- **操作系统**: Ubuntu 18.04+ / Debian 10+
- **Web服务器**: nginx
- **权限**: root权限
- **网络**: 公网IP和域名解析

## ⚡ 快速开始

### 1. 下载脚本
```bash
cd /home/admin/nginx-domain-manager
chmod +x add-subdomain.sh
```

### 2. 运行脚本
```bash
sudo ./add-subdomain.sh
```

### 3. 按提示操作
- 输入域名 (如: `blog.example.com`)
- 选择网站类型 (1-静态, 2-代理, 3-PHP)
- 根据类型填写额外配置

### 4. 申请SSL证书
```bash
sudo certbot --nginx -d your-domain.com
```

## 📝 使用示例

### 静态网站示例
```bash
sudo ./add-subdomain.sh
# 输入: blog.wedaren.tech
# 选择: 1 (静态网站)
# 自动创建: /var/www/blog.wedaren.tech/
```

### 反向代理示例
```bash
sudo ./add-subdomain.sh
# 输入: api.wedaren.tech  
# 选择: 2 (反向代理)
# 输入后端端口: 3000
# 代理到: localhost:3000
```

### PHP网站示例
```bash
sudo ./add-subdomain.sh
# 输入: app.wedaren.tech
# 选择: 3 (PHP网站)
# 自动安装PHP-FPM和依赖
```

## 🚨 故障排除

### 常见问题

**1. nginx配置测试失败**
```bash
sudo nginx -t  # 检查配置语法
sudo journalctl -u nginx -f  # 查看错误日志
```

**2. 域名无法访问**
- 检查DNS解析是否正确
- 确认防火墙设置
- 验证nginx是否运行

**3. SSL证书问题**
```bash
sudo certbot certificates  # 查看证书状态
sudo certbot renew --dry-run  # 测试续期
```

---
*最后更新: 2025年8月10日*
