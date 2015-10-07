# encoding: utf-8

class UserSessionsController < ApplicationController
  before_filter :login_required, :only => [ :destroy ]

  respond_to :html

  # omniauth callback method
  def create
    omniauth = env['omniauth.auth']
    logger.debug "+++ #{omniauth}"

    user = User.find_by_uid(omniauth['uid'])
    if not user
      # New user registration
      user = User.new(:uid => omniauth['uid'])
    end
    user.email = omniauth['info']['email']    
    user.name = omniauth['info']['name']
    user.salt = omniauth['info']['salt']
    user.save

    #p omniauth

    # Currently storing all the info
    session[:user_id] = omniauth

    flash[:notice] = "登录成功."
    login_suc_url = cookies[LOGIN_SUC_CODE] || admin_root_path
    cookies.delete(LOGIN_SUC_CODE, :domain => GlobalSettings.cookie_domain) unless cookies[LOGIN_SUC_CODE].nil?
    redirect_to login_suc_url
  end

  # Omniauth failure callback
  def failure
    flash[:notice] = params[:message]

  end

  # logout - Clear our rack session BUT essentially redirect to the provider
  # to clean up the Devise session from there too !
  def destroy
    session[:user_id] = nil

    flash[:notice] = '退出成功.'
    redirect_to "#{CUSTOM_PROVIDER_URL}/users/sign_out"
  end
end
