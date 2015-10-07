# encoding: utf-8
class Admin::FriendLinksController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin"
  
  # GET /friend_links
  # GET /friend_links.json
  def index
    @search = FriendLink.search(params[:search])
    @friend_links = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('id DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @friend_links }
    end
  end

  # GET /friend_links/1
  # GET /friend_links/1.json
  def show
    @friend_link = FriendLink.find(params[:id])
    
    drop_breadcrumb(@friend_link.name, admin_friend_link_path(@friend_link))
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @friend_link }
    end
  end

  # GET /friend_links/new
  # GET /friend_links/new.json
  def new
    @friend_link = FriendLink.new
    
    drop_breadcrumb('新增')
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @friend_link }
    end
  end

  # GET /friend_links/1/edit
  def edit
    @friend_link = FriendLink.find(params[:id])
    
    drop_breadcrumb(@friend_link.name, admin_friend_link_path(@friend_link))
    drop_breadcrumb('修改')
  end

  # POST /friend_links
  # POST /friend_links.json
  def create
    @friend_link = FriendLink.new(friend_link_params)
    @friend_link.user_id = @current_user.uid
    @friend_link.user_name = @current_user.name
    
    # upload image
    upload_hash = FileUploadUtil.uploadImage(params[:friend_link][:img_path],"friendlink")
    if upload_hash[:status] == 'error'
      respond_to do |format|
        flash[:notice] = upload_hash[:msg]
        format.html { render action: "new" }
        format.json { render json: @friend_link.errors, status: :unprocessable_entity }
      end
      return
    end
    @friend_link.img_path = upload_hash[:file_name] unless params[:friend_link][:img_path].nil?
    
    respond_to do |format|
      if @friend_link.save
        format.html { redirect_to admin_friend_link_path(@friend_link), notice: '友情链接创建成功.' }
        format.json { render json: @friend_link, status: :created, location: @friend_link }
      else
        format.html { render action: "new" }
        format.json { render json: @friend_link.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /friend_links/1
  # PATCH/PUT /friend_links/1.json
  def update
    @friend_link = FriendLink.find(params[:id])
    
    upload_hash = FileUploadUtil.uploadImage(params[:friend_link][:img_path], "friendlink", @friend_link.img_path)
    if upload_hash[:status] == 'error'
      respond_to do |format|
        flash[:notice] = upload_hash[:msg]
        format.html { render action: "new" }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
      return
    end

    @friend_link.img_path = upload_hash[:file_name] unless params[:friend_link][:img_path].nil?
    
    respond_to do |format|
      if @friend_link.update_attributes(friend_link_params)
        format.html { redirect_to admin_friend_link_path(@friend_link), notice: '友情链接修改成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @friend_link.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /friend_links/1
  # DELETE /friend_links/1.json
  def destroy
    @friend_link = FriendLink.find(params[:id])
    @friend_link.destroy

    respond_to do |format|
      format.html { redirect_to admin_friend_links_path }
      format.json { head :no_content }
    end
  end

  private

    def friend_link_params
      params.require(:friend_link).permit(:addr, :description, :img_path, :name, :sortrank, :status, :type_ids)
    end
    
    def init_breadcrumb_and_module_name
      set_query_url(FriendLink, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("友情链接", query_url(admin_friend_links_path, FriendLink, @current_user.uid))
      @_module_name = 'friend_link'
      @__module_name = 'FriendLink'
      @page_title = "友情链接管理"
    end
end
