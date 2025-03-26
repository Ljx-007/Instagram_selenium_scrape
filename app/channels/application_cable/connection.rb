module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # 这里可以添加用户认证逻辑
    # identified_by :current_user
    # 
    # def connect
    #   self.current_user = find_verified_user
    # end
    # 
    # private
    #   def find_verified_user
    #     # 用户认证逻辑
    #   end
  end
end