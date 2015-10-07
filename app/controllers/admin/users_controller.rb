# encoding: utf-8

class Admin::UsersController < ApplicationController
  
  before_filter :login_required
  load_and_authorize_resource
  before_filter :init_breadcrumb_and_module_name
  layout "admin"
  
  # GET /notes
  # GET /notes.json
  def index
    respond_to do |format|
      format.html { 
        @search = User.search(params[:search])
        @users = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('uid DESC')
      }
      format.json {
        render json: User.select("uid, name").where("name like '%#{params[:q]}%'").collect! {|x| {:id => x.uid, :name => x.name}}
      }
    end
  end

  # GET /notes/1
  # GET /notes/1.json
  def show
    @user = User.find(params[:id])
    drop_breadcrumb(@user.uid, admin_user_path(@user))
  end

  private
    
    def init_breadcrumb_and_module_name
      set_query_url(User, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("用户", query_url(admin_users_path, User, @current_user.uid))
      @_module_name = 'user'
      @__module_name = 'User'
      @_module_new = false
      @_module_edit = false
      @_module_delete = false
    end
end
