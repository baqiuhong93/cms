class User < ActiveRecord::Base
  after_initialize :default_values
  
  self.primary_key = "uid"
  
  attr_accessible :uid, :email, :name, :salt, :today_article_count, :total_article_count
  
  def security_key
    Digest::MD5.hexdigest(self.uid.to_s + "_" + self.salt + "_" + DateTime.now.strftime("%Y%m%d"))
  end
  
  def default_values
    if self.new_record?
      self.today_article_count = 0 if self.today_article_count.nil?
      self.total_article_count = 0 if self.total_article_count.nil?
    end
  end
  
end
