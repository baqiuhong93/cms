# encoding: utf-8
class OriginAddr < ActiveRecord::Base
  set_table_name "origins"
  
  after_save :delete_cache
  
  attr_accessible :name, :addr, :user_id, :user_name
  
  validates_presence_of :name, :message => "名称不能为空!"
  
  validates_presence_of :addr, :message => "地址不能为空!"
  
  has_many :articles, :foreign_key => :origin_id
  
  private
  
  def delete_cache
    APP_CACHE.delete("origin_" + self.id.to_s)
  end
end
