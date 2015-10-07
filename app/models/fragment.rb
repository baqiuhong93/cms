# encoding: utf-8
class Fragment < ActiveRecord::Base
  
  after_initialize :default_values
  
  after_save :delete_cache
  
  
  belongs_to :user
  attr_accessible :content, :title, :type_id, :user_name, :unique_code, :user
  
  
  validates_presence_of :title, :message => "名称不能为空!"
  
  validates_uniqueness_of :unique_code, :message => "编码必须唯一!", :allow_blank => true
  
  validates_presence_of :content, :message => "内容不能为空!"
  
  def self.type_hash
    {0 => "官网和网校", 1 => "分校头部导航", 2 => "分校第一通栏", 3 => "分校第二通栏", 4 => "分校列表上侧广告", 5 => "分校课程导航", 6 => "分校首页头条", 7 => "分校头条右侧", 8 => "分校上课现场", 9 => "分校底部地址", 10 => "分校列表右侧课程", 11 => "分校列表右侧广告", 12 => "分校摘要下侧广告", 13 => "个人中心"}
  end
  
  private
  
  def delete_cache
    APP_CACHE.delete("fragment_#{self.id.to_s}")
    PUBLIC_CACHE.delete("fragment_#{self.id.to_s}")
    APP_CACHE.delete("fragment_#{self.unique_code}") if self.unique_code.present?
    PUBLIC_CACHE.delete("fragment_#{self.unique_code}") if self.unique_code.present?
  end
  
  def default_values
    self.unique_code = '' if self.unique_code.nil?
  end
  
end
