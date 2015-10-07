class ApplicationController < ActionController::Base
  protect_from_forgery
  has_mobile_fu
  #before_filter :force_mobile_format
  
  before_filter :set_breadcrumbs
  
  rescue_from CanCan::AccessDenied do |exception|
      render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false
        ## to avoid deprecation warnings with Rails 3.2.x (and incidentally using Ruby 1.9.3 hash syntax)
        ## this render call should be:
        # render file: "#{Rails.root}/public/403", formats: [:html], status: 403, layout: false
  end
  
  def login_required
    if !current_user
      respond_to do |format|
        format.html  {
          cookies[LOGIN_SUC_CODE] = { :value => request.original_url, :domain => GlobalSettings.cookie_domain} if cookies[LOGIN_SUC_CODE].nil? && !request.xhr?
          redirect_to '/auth/joshid'
        }
        format.json {
          render :json => { 'error' => 'Access Denied' }.to_json
        }
      end
    end
  end

  def current_user
    return nil unless session[:user_id]
    @current_user ||= User.find_by_uid(session[:user_id]['uid'])
  end
  
  
  def paper_trail_enabled_for_controller
    request.path.start_with?("/admin/")
  end
  
  def user_for_paper_trail
    current_user ? current_user.name : 'System'
  end
  
  def set_breadcrumbs
    @breadcrumbs = ["<a href='/admin'>Home</a>".html_safe]
  end
    
    #def drop_breadcrumb(title, path)
    #  if @_nav.nil?
    #    @_nav = "<a href='/admin/index'>Home</a>"
    #  end
    #  @_nav = @_nav + " > " + "<a href='#{path}'>#{title}</a>"
    #end
    
  def add_jsp_define(content)
    '<%@ page language="java" import="java.util.*" pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %><%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %><%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %><%@ taglib prefix="cms" uri="http://www.weimini.com/tags" %>'+content
  end

  def add_article_jsp_define(content)
    '<%@ page language="java" import="java.util.*" pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %><%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %><%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %><%@ taglib prefix="cms" uri="http://www.weimini.com/tags" %><%@include file="/util/mobile_check.jsp" %>'+content
  end
    
  def replace_for_jsp_el(content, is_upload = true)
    return '' if content.nil?
    
    tag_start = content.index("<cms:list")
    tag_end = content.index("</cms:list>")
    new_content = ''
    while !tag_start.nil? && !tag_end.nil? do
      if is_upload
        new_content += content[0...tag_start] + content[tag_start...tag_end+11].gsub("${","\\${")
      else
        new_content += content[0...tag_start] + content[tag_start...tag_end+11].gsub("\\${", "${")
      end
      content = content[tag_end+11..content.length]
      tag_start = content.index("<cms:list")
      tag_end = content.index("</cms:list>")
    end
    return new_content + content
  end
    
    
  def query_url(url, model, uid)
    _qs = APP_CACHE.get("_#{model.to_s}_qs_#{uid.to_s}")
    url + ((_qs.nil? || _qs.empty?) ? "" : "?#{_qs}")
  end
    
  
  def set_query_url(model, uid)
    APP_CACHE.set("_#{model.to_s}_qs_#{uid.to_s}", request.query_string) unless request.xhr?
  end
end
