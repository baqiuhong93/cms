# encoding: utf-8
class HtmlTemplate < ActiveRecord::Base
  
  after_update :delete_cache
  
  after_initialize :default_values
  
  belongs_to :user
  attr_accessible :name, :type_id, :down_code, :user_name, :status, :released, :created_at
  
  validates_presence_of :name, :message => "名称不能为空!"
  
  has_many :nodes, :class_name => "Node", :foreign_key => "temp_node_id"
  
  has_many :articles, :class_name => "Node", :foreign_key => "temp_article_id"
  
  def jsp_path
    self.jsp_dir + self.id.to_s + ".jsp"
  end
  
  def jsp_temp_path
    self.jsp_path.gsub(".jsp", "_temp.jsp").strip
  end
  
  def view_path
    if self.status == 1
      self.jsp_temp_path.strip
    else
      self.jsp_path.strip
    end
  end
  
  def jsp_dir
    "/templates/" + self.created_at.strftime("%Y/%m/%d/")
  end
  
  def self.type_hash
    {1 => "公共", 2 => "列表", 3 => "文章", 4 => "头部", 5 => "尾部", 6 => "列表片段", 7 => "相关文章片段"}
  end
  
  def released?
    (self.type_id == 2 || self.type_id == 3) ? true : false
  end
  
  def mobanpianduan?
    if self.type_id == 6
      true
    else
      false
    end
  end
  
  private
  
  def delete_cache
    APP_CACHE.delete("html_template_#{self.id.to_s}")
  end
  
  def default_values
    if self.new_record?
      self.status = 1 if self.status.nil?
      self.released = false
      self.created_at = DateTime.now if self.created_at.nil?
    end
  end
  
end
