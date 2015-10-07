# encoding: utf-8
class MessageTablesController < ApplicationController
  
  # GET /message_tables
  # GET /message_tables.json
  def index
  end

  # GET /message_tables
  # GET /message_tables.json
  def create
    if !params[:callback].nil? && !params[:id].nil?
      @message_table = MessageTable.where("id = ?", params[:id]).first
      if @message_table.nil?
        render :text => "#{params[:callback]}({\"status\" : \"error\", \"msg\" : \"信息表不存在!\"})"
      elsif !@message_table.effective?
        render :text => "#{params[:callback]}({\"status\" : \"error\", \"msg\" : \"信息表已过期!\"})"
      else
        _message_object = {}
        @message_table.message_columns.each do |message_column|
          if message_column.type_id == 3
            if params[:message_table][message_column.column_name.to_sym].nil?
              _message_object[message_column.column_name] = []
            else
              if params[:message_table][message_column.column_name.to_sym].kind_of?(Array)
                _message_object[message_column.column_name] = params[:message_table][message_column.column_name.to_sym]
              else
                _message_object[message_column.column_name] = [].push(params[:message_table][message_column.column_name.to_sym])
              end
            end
          else
            _message_object[message_column.column_name] = params[:message_table][message_column.column_name.to_sym] || ''
          end
        end
        @message_text = MessageText.new
        @message_text.message_table_id = @message_table.id
        @message_text.text = _message_object
        @message_text.ip = request.remote_ip
        @message_text.created_at = DateTime.now
        @message_text.updated_at = DateTime.now
        if !current_user.nil?
          @message_text.user_id = current_user.uid
          @message_text.user_name = current_user.name
        end
        @message_text.save
        render :text => "#{params[:callback]}({\"status\" : \"success\", \"msg\" : \"信息提交成功!\"})"
      end
      
    end
  end

end
