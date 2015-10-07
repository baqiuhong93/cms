# encoding: utf-8
class FriendLink < ActiveRecord::Base
  after_initialize :default_values
  
  after_save :delete_cache
  
  belongs_to :user
  
  attr_accessible :addr, :description, :img_path, :name, :sortrank, :status, :type_ids, :user_id, :user_name
  
  def status_text
    if self.status == 1
      "有效"
    elsif self.status == 0
      "无效"
    else
      "未知"
    end
  end
  
  private
  
  def delete_cache
    APP_CACHE.delete("friend_link")
  end
  
  def default_values
    if self.new_record?
      self.sortrank = 10 if self.sortrank.nil?
      self.status = 1 if self.status.nil?
    end
  end
end
