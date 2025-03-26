class HomeController < ApplicationController
  #这里用于声明页面
  def index
    redirect_to topics_path
  end
end
