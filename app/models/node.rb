# encoding: utf-8
class Node < ActiveRecord::Base
  
  after_initialize :default_values
  
  after_update :delete_cache
  
  has_ancestry {:cache_depth}
  
  belongs_to :user
  
  belongs_to :domain
  
  belongs_to :temp_article, :class_name => "HtmlTemplate", :foreign_key => "temp_article_id"
  
  belongs_to :temp_node, :class_name => "HtmlTemplate", :foreign_key => "temp_node_id"
  
  has_many :articles
  
  attr_accessible :click, :keywords, :description, :domain_id, :node_type, :nav, :name, :unique_code, :pId, :per_page_size, :sortrank, :temp_article_id, :temp_node_id, :url, :article_url, :user_name, :user, :list_order_id, :released, :status, :down_code, :show_name
  
  validates_presence_of :name, :message => "名称不能为空!"
  
  validates_presence_of :node_type, :message => "节点类型不能为空!"
  
  validates_uniqueness_of :unique_code, :message => "编码必须唯一!", :allow_blank => true

  validates_uniqueness_of :url, :on => :create, :scope => [:domain_id], :message => "地址必须唯一!"
  
  def self.node_type_hash
    {1 => "栏目", 2 => "列表"}
  end
  
  def self.list_order_hash
    {1 => "推介降序、ID降序", 2 => "修改日期降序"}
  end
  
  def self.list_order_id_hash
    {1 => "commend DESC, id DESC", 2 => "updated_at DESC"}
  end
  
  def self.subject_type_hash
    {1 => "专题1", 2 => "专题2", 3 => "专题3", 4 => "专题4", 5 => "专题5"}
  end
  
  def article_count
    APP_CACHE.fetch("node_article_count_#{self.id.to_s}", 0) do
      _ac = Article.where("released = 1 and ancestry like '%,#{self.id.to_s},%'").count
      _ac == 0 ? 1 : _ac
    end
  end
  
  def list?
    self.node_type == 2 ? true : false
  end
  
  def preview_url
    if !self.temp_node.nil?
      self.list? ? self.temp_node.view_path + "?pageNo=1&id=#{self.id.to_s}&type=2&preview=1" : self.temp_node.view_path + "?id=#{self.id.to_s}&type=2&preview=1"
    else
      if self.status == 1
        "/nodes/#{self.domain.addr}#{self.url.gsub('.html','_temp.jsp')}?id=#{self.id.to_s}&type=1&preview=1"
      else
        "/nodes/#{self.domain.addr}#{self.url.gsub('.html','.jsp')}?id=#{self.id.to_s}&type=1&preview=1"
      end
    end
  end
  
  def view_url
    if !self.temp_node.nil?
      if self.list?
        self.temp_node.jsp_path + "?pageNo=#pageNo&id=#{self.id.to_s}&type=2"
      else
        self.temp_node.jsp_path + "?id=#{self.id.to_s}&type=2"
      end
    else
      "/nodes/#{self.domain.addr}#{self.url.gsub('.html','.jsp')}?id=#{self.id.to_s}&type=1"
    end
  end
  
  def html_view_url
    if !self.temp_node.nil?
      self.list? ? self.temp_node.view_path + "?pageNo=#pageNo&id=#{self.id.to_s}" :  self.temp_node.view_path + "?id=#{self.id.to_s}"
    else
      (!self.domain.nil? && !self.url.nil?) ? "/nodes/#{self.domain.addr}#{self.url}?id=#{self.id.to_s}" : ""
    end
  end
  
  def html_page_no_file
    GlobalSettings.html_path + "/" + self.domain.addr + self.url.gsub("#id", self.id.to_s)
  end
  
  def jsp_path
    '/nodes/' + self.domain.addr + self.url.gsub(".html",".jsp")
  end
  
  def jsp_temp_path
    self.jsp_path.gsub(".jsp","_temp.jsp").strip
  end
  
  def html_url
    (!self.domain.nil? && !self.url.nil?) ? "http://#{self.domain.addr}#{self.url.gsub('#id', self.id.to_s).gsub('#pageNo', '1')}" : ""
  end
  
  def html_page_no_url
    (!self.domain.nil? && !self.url.nil?) ? "http://#{self.domain.addr}#{self.url.gsub('#id', self.id.to_s)}" : ""
  end

  def mobile_list_url
    "/mobile/list/#{self.id}"
  end

  def mobile_huizong_url
    "/mobile/huizong/#{self.id}"
  end
  
  def nav_text
    self.nav ? '是' : '否'
  end
  
  def status_text
    if self.status == -1
      '无效'
    elsif self.status == 1
      '有效'
    elsif self.status == 2
      '已发布'
    end
  end
  
  def generate_html
    _node_dir = self.html_page_no_file[0...self.html_page_no_file.rindex("/")]
    FileUtils.mkpath _node_dir unless File.exists?(_node_dir)
    if self.list?
      _page_count = (self.article_count % self.per_page_size == 0) ? (self.article_count/self.per_page_size) : (self.article_count/self.per_page_size + 1)
      _page_count.times do |index|
        #if !File.exists?(self.html_page_no_file.gsub("#pageNo", (index+1).to_s))
          File.open(self.html_page_no_file.gsub("#pageNo", (index+1).to_s), 'wb') { |file|
            file.write("<!--# include file=\"#{self.view_url.gsub('#pageNo', (index+1).to_s)}\" -->")
          }
        #end
      end
    else
      #if !File.exists?(self.html_page_no_file)
        File.open(self.html_page_no_file, 'wb') { |file|
          file.write("<!--# include file=\"#{self.view_url}\" -->")
        }
      #end
    end
  end
  
  def delete_child_nodes_cache
    APP_CACHE.delete("child_nodes_#{self.pId.to_s}")
  end
  
  def purge_cache
    if GlobalSettings.varnish_cache
      if self.list?
        system("curl -X #{GlobalSettings.varnish_cache_directory_key} self.html_page_no_url[0...self.html_page_no_url.index('#pageNo')]")
      else
        system("curl -X #{GlobalSettings.varnish_cache_url_key} self.html_url.gsub('/index.html','')")
      end
    end
  end
  
  private
  
  def delete_cache
    APP_CACHE.delete("node_#{self.id.to_s}")
    APP_CACHE.delete("node_uc_#{self.unique_code}") if self.unique_code.present?
  end
  
  def default_values
    if self.new_record?
      self.click = 1 if self.click.nil?
      self.per_page_size = GlobalSettings.article_per_page_size if self.per_page_size.nil?
      self.sortrank = 10 if self.sortrank.nil?
      self.list_order_id = 1 if self.list_order_id.nil?
      self.redirect_url = '' if self.redirect_url.nil?
      self.status = 1 if self.status.nil?
      self.keywords = '' if self.keywords.nil?
      self.description = '' if self.description.nil?
      self.released = false if self.released.nil?
      self.released_num = 0 if self.released_num.nil?
      self.article_url = '' if self.article_url.nil?
      self.nav = true if self.nav.nil?
      self.show_name = '' if self.show_name.nil?
    end
  end
end
