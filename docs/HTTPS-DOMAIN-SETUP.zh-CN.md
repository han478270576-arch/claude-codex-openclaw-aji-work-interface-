# 域名与 HTTPS 绑定说明

## 当前域名结构

- `ajiclaw.com`：公开落地页
- `www.ajiclaw.com`：301 跳转到 `https://ajiclaw.com`
- `prod.ajiclaw.com`：OpenClaw 生产环境
- `test.ajiclaw.com`：OpenClaw 测试环境

## 当前服务器映射

- `prod.ajiclaw.com` -> `127.0.0.1:18789`
- `test.ajiclaw.com` -> `127.0.0.1:18790`

## 绑定步骤

1. 在域名商配置 DNS：
   - `A @ -> 64.188.27.231`
   - `A prod -> 64.188.27.231`
   - `A test -> 64.188.27.231`
   - `CNAME www -> ajiclaw.com`
2. 在服务器安装 `Caddy`
3. 使用 `Caddy` 自动申请 Let’s Encrypt 证书
4. 通过反向代理把生产和测试域名分别指向对应本地端口

## 入口规则

- 对外公开说明页只放在根域名
- 真正的生产入口放在 `prod` 子域名
- 真正的测试入口放在 `test` 子域名
- 不在公开页面里暴露带 token 的私有 URL

## 当前访问建议

- 生产控制台：使用已保存的带 token 书签访问 `https://prod.ajiclaw.com`
- 测试控制台：使用已保存的带 token 书签访问 `https://test.ajiclaw.com`
- 公共说明入口：`https://ajiclaw.com`
