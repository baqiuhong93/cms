# encoding: utf-8
class MessageTable < ActiveRecord::Base
  
  after_initialize :default_values
  
  attr_accessible :description, :end_at, :logined, :name, :start_at, :table_name, :user_id, :user_name, :message_columns_attributes, :show_front, :verify
  
  has_many :message_columns, :dependent => :destroy
  
  accepts_nested_attributes_for :message_columns, :reject_if => lambda { |a| a[:name].blank? }, :allow_destroy => true
  
  validates_uniqueness_of :table_name, :on => :create, :message => "英文名必须唯一"
  
  def logined_text
    self.logined ? "是" : "否"
  end
  
  def effective?
    if !self.start_at.nil? && !self.end_at.nil?
      if DateTime.now.to_i >= self.start_at.to_i && DateTime.now.to_i <= self.end_at.to_i
        return true
      end
    end
    
    if !self.start_at.nil?
      if self.start_at.to_i > DateTime.now.to_i
        return false
      end
    end
    
    if !self.end_at.nil?
      if self.end_at.to_i < DateTime.now.to_i
        return false
      end
    end
    return true
  end
  
  def message_table_form
    _form_str = "<form id='info_#{self.table_name}_#{self.id}'><br>"
    _form_str += "<input type='hidden' name='id' value='#{self.id}' id='id'><br>"
  	self.message_columns.each do |mc|
  	  _form_str += mc.column_text
    end
    _form_str += "<input type='button' value='提交' id='info_#{self.table_name}_#{self.id}_button'><br>"	
    _form_str += "</form><br>"
    _form_str += "<script type='text/javascript'><br>"
    _form_str += "$('#info_#{self.table_name}_#{self.id}_button').click(function(){"
    _form_str += "  $.getJSON('#{GlobalSettings.cms_domain}/message_tables/create.json?callback=?',$('#info_#{self.table_name}_#{self.id}').serializeObject(),function (data){<br>"
    _form_str += "     if(data.status == 'success') {<br>"
    _form_str += "        $(':input','#info_#{self.table_name}_#{self.id}').not(':button, :submit, :reset, :hidden').val('').removeAttr('checked').removeAttr('selected');"
    _form_str += "     }<br>"
    _form_str += "     alert(data.msg);"
    _form_str += "  });<br>"
    _form_str += "});<br>"
    _form_str += "</script>"
    _form_str
  end
  
  private
  
  def default_values
    if self.new_record?
      self.show_front = false if self.show_front.nil?
      self.verify = false if self.verify.nil?
      self.description = '' if self.description.nil?
      self.logined = false if self.logined.nil?
    end
  end
  
end
