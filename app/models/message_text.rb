# encoding: utf-8
class MessageText
  include Mongoid::Document
  
  field :message_table_id, type:Integer
  field :user_id, type:Integer
  field :user_name, type:String
  field :created_at, type:DateTime
  field :updated_at, type:DateTime
  field :ip, type:String
  field :text, type:Hash
end
