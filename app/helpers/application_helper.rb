# encoding: utf-8
module ApplicationHelper
  
  def format_date(datetime, default_val=nil)
    return  (default_val.nil? ? '' :  default_val) if datetime.nil?
    return datetime.strftime("%Y-%m-%d %H:%M:%S")
  end
  
  
  def file_url(path)
    path.nil? ? GlobalSettings.upload_view_url : GlobalSettings.upload_view_url + path
  end
  
  def query_url(url, model, uid)
    _qs = APP_CACHE.get("_#{model.to_s}_qs_#{uid.to_s}")
    url + ((_qs.nil? || _qs.empty?) ? "" : "?#{_qs}")
  end

  def will_paginate(collection, options = {}) 
    options.merge!({ 
    :previous_label => '上一页', 
    :next_label => '下一页' 
    }) 
    super(collection, options) 
  end

end
