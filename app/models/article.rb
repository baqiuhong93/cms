# encoding: utf-8
class Article < ActiveRecord::Base
  
  before_save :init_ancestry
  
  after_initialize :default_values
  
  after_update :delete_cache
  
  acts_as_taggable
  
  belongs_to :origin, :class_name => "OriginAddr", :foreign_key => "origin_id"
  belongs_to :node
  belongs_to :user
  belongs_to :article_text, :dependent => :destroy
  belongs_to :domain
  
  attr_accessible :node_id, :click, :commend, :status, :description, :img_path, :page_size, :released, :released_at, :short_title, :sortrank, :sub_node_ids, :sub_title, :title, :url, :user, :user_name, :writer, :origin_id, :article_text_attributes, :article_text_id, :tag_list, :created_at, :domain_id, :ancestry, :seo_keyword, :seo_description
  
  accepts_nested_attributes_for :article_text
  
  validates_presence_of :title, :on => :create, :message => "标题不能为空!"
  validates_presence_of :article_text, :message => "内容不能为空!"
  
  def commend_text
    self.commend ? "是" : "否"
  end
  
  def view_url
    "#{self.node.temp_article.jsp_path}?id=#{self.id.to_s}&pageNo=#pageNo"
  end
  
  def preview_url
    "#{self.node.temp_article.view_path}?id=#{self.id.to_s}&pageNo=1&preview=1"
  end
  
  def html_view_url
    (!self.node.nil? && !self.node.temp_article.nil?) ? "#{self.node.temp_article.view_path}?id=#{self.id.to_s}&pageNo=#pageNo" : "/404.html"
  end
  
  def html_page_no_file
    GlobalSettings.html_path + "/" + self.node.domain.addr + self.url
  end
  
  def html_page_no_url
    "http://#{self.node.domain.addr}#{self.url.gsub('#id', self.id.to_s)}"
  end

  def html_page_first_url
    "/mobile/show/#{self.id}"
  end
  
  def sub_node_string
    sub_nodes = []
    self.sub_node_ids.split(",").each do |sub_cate|
      _node = Node.where("id = ?", sub_cate).first
      sub_nodes.push("{'id': #{_node.id}, 'name': '#{_node.name}'}");
    end
    "[#{sub_nodes.join(',')}]"
  end
  
  def self.status_hash
    {-1 => "无效", 1 => "有效", 2 => "已发布"}
  end
  
  def article_texts
    self.article_text.content.split('<div style="page-break-after: always;"><span style="display: none;">&nbsp;</span></div>')
  end

  def status_text
    if self.status == -1
      '无效'
    elsif self.status == 1
      '有效'
    elsif self.status == 2
      '已发布'
    else
      '---'
    end
  end
  
  def generate_html(generate_node=true)
    _article_dir = self.html_page_no_file[0...self.html_page_no_file.rindex("/")]
    FileUtils.mkpath _article_dir unless File.exists?(_article_dir)
    self.page_size.times do |index|
      #if !File.exists?(self.html_page_no_file.gsub("#pageNo", (index+1).to_s))
        File.open(self.html_page_no_file.gsub("#pageNo", (index+1).to_s), 'wb') do |file|
          file.write("<!--# include file=\"#{self.view_url.gsub('#pageNo', (index+1).to_s)}\" -->")
        end
      #end
    end
    
    if generate_node
      self.ancestry.split(",").each do |_cate_id|
        if _cate_id.present?
          _node = Node.where("id = ?", _cate_id).first
          _node.generate_html unless _node.nil?
        end
      end unless self.ancestry.nil?
    end
    
  end
  
  def update_status_and_reseased
    self.update_attributes({:status => 2, :released => true})
    
    self.tags.each do |tag|
      APP_CACHE.delete("taggable_#{tag.id.to_s}_Article")
    end
    
    self.ancestry.split(",").each do |_cate_id|
      if _cate_id.present?
        APP_CACHE.delete("node_article_count_#{_cate_id}")
      end
    end unless self.ancestry.nil?
  end
  
  def purge_cache
    if GlobalSettings.varnish_cache && self.released
      system("curl -X #{GlobalSettings.varnish_cache_directory_key} self.html_page_no_url[0...self.html_page_no_url.index('#pageNo')]")
      _node = Node.where("id = ?", self.node_id).first
      _node.purge_cache
      self.ancestry.split(",").each do |_cate_id|
        if _cate_id.present?
          _node = Node.where("id = ?", _cate_id).first
          if _node.list?
            _node.purge_cache
          end
        end
      end unless self.ancestry.nil?
    end
  end
  
  private
  
  def init_ancestry
    _node = Node.where("id = ?", self.node_id).first
    
    _ancestry = [self.node_id]
    _node.ancestry.split("/").each do |_anc|
      _ancestry.push(_anc)
    end if !_node.nil? && !_node.ancestry.nil?
    
    self.sub_node_ids.split(",").each do |sub_node|
      _node = Node.where("id = ?", sub_node).first
      
      _ancestry.push(_node.id) unless  _node.nil?
      
      _node.ancestry.split("/").each do |_anc|
        _ancestry.push(_anc)
      end if !_node.nil? && !_node.ancestry.nil?
      
    end unless self.sub_node_ids.empty?
    
    self.ancestry = ',' + _ancestry.uniq.join(",") + "," if _ancestry.uniq.length > 0
  end
  
  def default_values
    if self.new_record?
      self.short_title = '' if self.short_title.nil?
      self.writer = '' if self.writer.nil?
      self.description = '' if self.description.nil?
      self.commend = false if self.commend.nil?
      self.sub_title = '' if self.sub_title.nil?
      self.img_path = '' if self.img_path.nil?
      self.sortrank = GlobalSettings.article_sortrank if self.sortrank.nil?
      self.click = 1 if self.click.nil?
      self.sub_node_ids = '' if self.sub_node_ids.nil?
      self.status = 1 if self.status.nil?
      self.released = false if self.released.nil?
      self.released_at = DateTime.now if self.released_at.nil?
      self.origin_id = 1 if self.origin_id.nil?
      self.ancestry = '' if self.ancestry.nil?
    end
  end
  
  def delete_cache
    APP_CACHE.delete("article_#{self.id.to_s}")
    APP_CACHE.delete("article_tag_ids_#{self.id.to_s}")
    self.tags.each do |tag|
      APP_CACHE.delete("taggable_#{tag.id.to_s}_Article")
    end
  end
end
