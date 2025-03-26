# Instagram Selenium Scraper

这是一个基于Ruby on Rails的Instagram数据爬虫项目，使用Selenium WebDriver自动化工具来抓取Instagram上的帖子数据。

## 功能特点

- 支持按话题(Topic)抓取Instagram帖子
- 自动处理Instagram登录认证
- 支持图片和视频内容的下载
- 支持提取帖子的标签(Hashtags)、点赞数等信息
- 支持任务取消和进度监控
- 使用代理服务器避免IP限制

## 技术栈

- Ruby 3.3.7
- Ruby on Rails 8.0.2
- Selenium WebDriver (Edge浏览器)
- SQLite3 数据库
- Docker 支持

## 系统要求

- Ruby 3.3.7
- Microsoft Edge 浏览器
- Node.js (用于前端资源管理)
- Docker (可选，用于容器化部署)

## 安装配置

### 本地开发环境

1. 克隆项目并安装依赖：
```bash
bundle install
```

2. 配置环境变量：
创建 `.env` 文件并设置以下变量：
```
INSTAGRAM_USERNAME=your_instagram_username
INSTAGRAM_PASSWORD=your_instagram_password
PROXY_HOST=your_proxy_host
PROXY_PORT=your_proxy_port
HEADLESS_BROWSER=true
MAX_POSTS=10
```

3. 初始化数据库：
```bash
bin/rails db:create
bin/rails db:migrate
```

### Docker部署

1. 构建Docker镜像：
```bash
docker build -t instagram-scraper .
```

2. 运行容器：
```bash
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<master_key> --name instagram-scraper instagram-scraper
```

## 使用说明

### 启动应用

```bash
bin/rails server
```

访问 `http://localhost:3000` 进入应用界面。

### 添加抓取话题

1. 在主页面添加新的话题(Topic)
2. 系统会自动开始抓取该话题下的Instagram帖子
3. 可以在话题详情页面查看抓取进度和结果

### 数据存储

- 图片文件保存在 `public/images` 目录
- 帖子数据存储在SQLite数据库中

## 开发指南

### 项目结构

- `app/services/instagram_scraper_service.rb`: 核心爬虫服务
- `app/models/instagram_post.rb`: Instagram帖子模型
- `app/models/topic.rb`: 话题模型

### 主要功能模块

1. 爬虫服务 (InstagramScraperService)
   - 处理Instagram登录
   - 实现帖子数据抓取
   - 管理浏览器会话

2. 数据模型
   - Topic: 管理抓取话题
   - InstagramPost: 存储帖子数据

### 注意事项

- 请遵守Instagram的使用条款和爬虫政策
- 建议使用代理服务器避免IP被封
- 定期检查和更新登录凭证
- 合理设置抓取间隔和数量限制

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件
