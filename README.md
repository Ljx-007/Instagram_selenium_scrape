# Instagram Selenium Scraper

这是一个基于Ruby on Rails的Instagram数据爬虫项目，使用Selenium WebDriver自动化工具来抓取Instagram上的帖子数据。<br><br>
**本项目使用edge浏览器进行自动化操作，请确保电脑上有版本一致的edge浏览器和msedgedriver**

## 功能特点

- 支持按话题(Topic)抓取Instagram帖子
- 将抓取下来的帖子展示在话题墙网页
- 支持图片和视频内容的下载
- 支持在话题墙查看帖子的图片、用户名、标签(Hashtags)、点赞数、发布时间等信息
- 支持任务取消和进度监控

## 技术栈

- Ruby 3.3.7
- Ruby on Rails 8.0.2
- Selenium WebDriver
- SQLite3 数据库


## 安装配置

### 本地开发环境

1. 克隆项目并安装依赖：
```bash
bundle install
```

2. 配置环境变量：
修改 `.env` 文件并设置以下变量：
```
INSTAGRAM_USERNAME=your_instagram_username
INSTAGRAM_PASSWORD=your_instagram_password
PROXY_HOST=your_proxy_host
PROXY_PORT=your_proxy_port
HEADLESS_BROWSER=true
MAX_POSTS=10  # 最大抓取帖子数
```


## 使用说明


### 启动应用

```bash
cd Instagram_selenium_scrape
rails server
```

访问 `http://localhost:3000` 进入应用界面。

### 添加抓取话题
1. 在主页面添加新的话题(Topic)
2. 系统会自动开始抓取该话题下的Instagram帖子
3. 在话题详情页下查看抓取后的结果
![image](https://github.com/user-attachments/assets/ce76c9cd-8d15-4904-bf01-ef8fb6a8f2b3)
![image](https://github.com/user-attachments/assets/9ca010f7-6eae-4a98-aeb3-c1708f61abfd)


### 注意事项

- 由于Instagram的反爬机制,普通爬虫不可用，于是使用selenium自动化模拟用户操作
- 项目启动前需安装版本匹配的浏览器以及对应的webdriver，本项目使用Edge浏览器（下面以edge浏览器举例）
- 将msedgedriver.exe放在浏览器安装目录的Application目录下，并将目录路径添加至环境变量
- 本项目基于selenium-webdriver实现，因此数据抓取时时间较长，请耐心等待。
- 本项目具有一定的不确定性（如Instagram检测异常登录，浏览器登陆成功后仍在登陆界面等），若您遇到以上情况，请刷新后重新尝试

