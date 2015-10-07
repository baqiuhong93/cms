# encoding: utf-8
class Admin::OriginsController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin"
  
  
  # GET /origins
  # GET /origins.json
  def index
    @search = OriginAddr.search(params[:search])
    @origins = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('id DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: OriginAddr.where("name like '%#{params[:q]}%'").paginate(:page => params[:page], :per_page => params[:page_limit]).order('id DESC') }
    end
  end

  # GET /origins/1
  # GET /origins/1.json
  def show
    @origin = OriginAddr.find(params[:id])

    drop_breadcrumb(@origin.name, admin_origin_path(@origin))
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @origin }
    end
  end

  # GET /origins/new
  # GET /origins/new.json
  def new
    @origin = OriginAddr.new
    
    drop_breadcrumb('新增')
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @origin }
    end
  end

  # GET /origins/1/edit
  def edit
    @origin = OriginAddr.find(params[:id])
    
    drop_breadcrumb(@origin.name, admin_origin_path(@origin))
    drop_breadcrumb('修改')
    
  end

  # POST /origins
  # POST /origins.json
  def create
    @origin = OriginAddr.new(origin_params)
    @origin.user_id = @current_user.uid
    @origin.user_name = @current_user.name
    respond_to do |format|
      if @origin.save
        format.html { redirect_to admin_origin_path(@origin), notice: '来源创建成功.' }
        format.json { render :json => {"status" => 1, "origin" => @origin} }
      else
        format.html { render action: "new" }
        format.json { render :json => {"status" => 0} }
      end
    end
  end

  # PATCH/PUT /origins/1
  # PATCH/PUT /origins/1.json
  def update
    @origin = OriginAddr.find(params[:id])

    respond_to do |format|
      if @origin.update_attributes(origin_params)
        format.html { redirect_to admin_origin_path(@origin), notice: '来源修改成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @origin.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /origins/1
  # DELETE /origins/1.json
  def destroy
    @origin = OriginAddr.find(params[:id])
    if @origin.articles.count == 0
      notice = "来源删除成功!"
      @origin.destroy
    else
      notice = "来源被文章引用，无法删除!"
    end

    respond_to do |format|
      format.html { redirect_to query_url(admin_origins_path, OriginAddr, @current_user.uid), notice: notice }
      format.json { head :no_content }
    end
  end

  private

    def origin_params
      params.require(:origin_addr).permit(:addr, :name)
    end
    
    def init_breadcrumb_and_module_name
      set_query_url(OriginAddr, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("来源", query_url(admin_origins_path, OriginAddr, @current_user.uid))
      @_module_name = 'origin'
      @__module_name = 'OriginAddr'
      @page_title = "来源管理"
    end
end
