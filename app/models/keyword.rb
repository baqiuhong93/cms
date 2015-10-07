# encoding: utf-8
class Keyword < ActiveRecord::Base
  after_initialize :default_values

  after_save :delete_cache
  after_destroy :delete_cache
  
  attr_accessible :name, :addr, :user_id, :user_name, :level
  
  validates_presence_of :name, :message => "名称不能为空!"
  
  validates_presence_of :addr, :message => "地址不能为空!"
  
  private
  
  def default_values
    if self.new_record?
      self.level = 5 if self.level.nil?
    end
  end

  def delete_cache
    APP_CACHE.delete("keywords")
  end
end
