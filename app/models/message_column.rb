class MessageColumn < ActiveRecord::Base
  
  after_initialize :default_values
  
  belongs_to :message_table
  attr_accessible :column_name, :name, :show_index, :export, :sortrank, :type_id, :json_value, :default_value, :query, :edit
  
  def self.type_hash
    {1 => "input", 2 => "select", 3 => "checkbox", 4 => "radio", 5 => "hidden"}
  end
  
  def column_text
    _t = ''
    if self.type_id == 1
      _t = "#{self.name} : <input type='input' name='message_table[#{self.column_name}]' value='#{self.default_value}' id='#{self.column_name}'><br>"
    elsif self.type_id == 2
      _t = "#{self.name} : "
      _t += "<select name='message_table[#{self.column_name}]' id='#{self.column_name}'>"
      self.json_value_hash.each do |k,v|
        if self.default_value == v.to_s
          _t += "<option value='#{k}' selected='selected'>#{v}</option>"
        else
          _t += "<option value='#{k}'>#{v}</option>"
        end
      end
      _t += "</select><br>"
    elsif self.type_id == 3
      _t = "#{self.name} : "
      self.json_value_hash.each do |k,v|
        _t += "<input type='checkbox' name='message_table[#{self.column_name}]' value='#{k}' id='#{self.column_name}'> #{v} "
      end
      _t += "<br>"
    elsif self.type_id == 4
      _t = "#{self.name} : "
      self.json_value_hash.each do |k,v|
        _t += "<input type='radio' name='message_table[#{self.column_name}]' value='#{k}' id='#{self.column_name}'> #{v} "
      end
      _t += "<br>"
    elsif self.type_id == 5
      _t = "<input type='hidden' name='message_table[#{self.column_name}]' value='#{self.default_value}' id='#{self.column_name}'><br>"
    else
      _t = "#{self.name} : <input type='input' name='message_table[#{self.column_name}]' value='#{self.default_value}' id='#{self.column_name}'><br>"
    end
    _t
  end
  
  def json_value_hash
    eval((self.json_value.empty? ? "{}" : self.json_value).gsub(":","=>"))
  end
  
  private
  
  def default_values
    if self.new_record?
      self.default_value = '' if self.default_value.nil?
      self.json_value = '' if self.json_value.nil?
      self.show_index = 0 if self.show_index.nil?
      self.query = false if self.query.nil?
      self.export = 0 if self.export.nil?
    end
  end
  
end
