# wxtest.wedaren.tech 域名配置

这个分支包含用于配置 `wxtest.wedaren.tech` 二级域名转发的脚本。

## 配置详情

- **域名**: wxtest.wedaren.tech
- **转发目标**: http://100.110.94.77:3000/
- **配置类型**: 反向代理

## 使用方法

1. 确保具有 root 权限
2. 运行配置脚本：
   ```bash
   sudo ./setup-wxtest-domain.sh
   ```

## 脚本功能

- 自动创建nginx反向代理配置
- 检查后端服务连接状态
- 测试nginx配置有效性
- 启用网站配置并重载nginx

## 配置文件位置

- nginx配置文件: `/etc/nginx/sites-available/wxtest.wedaren.tech`
- 启用的配置: `/etc/nginx/sites-enabled/wxtest.wedaren.tech`

## 后续步骤

### 启用HTTPS (推荐)

使用Let's Encrypt申请免费SSL证书：

```bash
sudo certbot --nginx -d wxtest.wedaren.tech
```

### 监控和日志

查看nginx状态：
```bash
sudo systemctl status nginx
```

查看访问日志：
```bash
sudo tail -f /var/log/nginx/access.log
```

查看错误日志：
```bash
sudo tail -f /var/log/nginx/error.log
```

### 测试连接

测试域名解析和响应：
```bash
curl -I http://wxtest.wedaren.tech
```

## 故障排除

1. **域名无法访问**
   - 检查DNS解析是否正确指向服务器IP
   - 确认防火墙允许80/443端口

2. **502 Bad Gateway错误**
   - 检查后端服务 `100.110.94.77:3000` 是否正常运行
   - 确认网络连接和防火墙设置

3. **nginx配置错误**
   - 使用 `sudo nginx -t` 测试配置语法
   - 查看 `/var/log/nginx/error.log` 获取详细错误信息

## 安全建议

1. 启用HTTPS加密
2. 配置适当的防火墙规则
3. 定期更新nginx和系统
4. 监控访问日志以发现异常活动
