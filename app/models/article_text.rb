# encoding: utf-8
class ArticleText < ActiveRecord::Base
  attr_accessible :content
  
  validates_presence_of :content, :message => "内容不能为空!"
end
