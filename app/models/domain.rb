# encoding: utf-8
class Domain < ActiveRecord::Base
  
  after_save :delete_cache
  
  attr_accessible :addr, :name, :user_id, :user_name
  
  validates_presence_of :name, :message => "名称不能为空!"
  
  validates_presence_of :addr, :message => "域名不能为空!"
  
  has_many :nodes
  
  private
  
  def delete_cache
    APP_CACHE.delete("domain_#{self.id.to_s}")
  end
end
