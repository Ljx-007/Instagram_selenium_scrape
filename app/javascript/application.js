// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// 页面加载完成后的初始化代码
document.addEventListener('DOMContentLoaded', function() {
  console.log('应用已初始化')
})
