class TopicsController < ApplicationController
  def index
    @topics = Topic.all.order(created_at: :desc)
    @topic = Topic.new
  end

  def show
    @topic = Topic.find(params[:id])
    @posts = @topic.instagram_posts.order(order_time: :desc).limit(10)
    
    # # 添加调试日志
    # Rails.logger.debug "获取到的帖子排序信息:"
    # @posts.each do |post|
    #   Rails.logger.debug "ID: #{post.id}, Order Time: #{post.order_time}, Posted At: #{post.posted_at}"
    # end
  end

  def create
    topic_name = params[:topic][:name].strip.downcase
    @topic = Topic.find_or_create_by_name(topic_name)
    
    if @topic.persisted?
      redirect_to topic_path(@topic)
    else
      @topics = Topic.all.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end
  
  def destroy
    @topic = Topic.find(params[:id])
    @topic.destroy
    
    redirect_to topics_path, notice: "话题 ##{@topic.name} 已成功删除"
  end

  def refresh
    @topic = Topic.find(params[:id])
    
    # 检查是否有正在进行的请求标记
    refresh_key = "topic_#{@topic.id}_refresh_in_progress"
    cancellation_key = "topic_#{@topic.id}_refresh_cancel"
    
    # 如果已经有正在进行的刷新，返回错误
    if Rails.cache.exist?(refresh_key)
      render json: { error: "已有一个正在进行的数据获取请求。请等待或刷新页面。" }, status: :conflict
      return
    end
    
    # 清除可能存在的取消标记
    Rails.cache.delete(cancellation_key)
    
    # 设置标记，表示正在进行刷新
    Rails.cache.write(refresh_key, true, expires_in: 5.minutes)
    
    begin
      # 使用InstagramPost模型中的方法获取数据
      result = InstagramPost.refresh_for_topic(@topic, cancellation_key)
      
      # 根据结果返回JSON响应
      if result[:success]
        render json: { 
          success: true,
          message: result[:new_posts].empty? ? "没有新的帖子" : "成功获取#{result[:new_posts].length}条最新帖子"
        }
      elsif result[:cancelled]
        render json: { 
          cancelled: true,
          message: "数据获取已取消"
        }
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    ensure
      # 清除正在进行的请求标记
      Rails.cache.delete(refresh_key)
      Rails.cache.delete(cancellation_key)
    end
  end

  # 取消刷新操作
  def cancel_refresh
    @topic = Topic.find(params[:id])
    
    # 设置取消标记
    cancellation_key = "topic_#{@topic.id}_refresh_cancel"
    Rails.cache.write(cancellation_key, true, expires_in: 5.minutes)
    
    render json: { success: true, message: "已发送取消请求" }
  end

  private

  def topic_params
    params.require(:topic).permit(:name)
  end
end