# encoding: utf-8
class Admin::HomeController < ApplicationController
  before_filter :login_required
  layout "admin"
  def index
    
  end
end