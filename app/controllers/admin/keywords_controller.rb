# encoding: utf-8
class Admin::KeywordsController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin"
  
  # GET /keywords
  # GET /keywords.json
  def index
    @search = Keyword.search(params[:search])
    @keywords = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('id DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @keywords }
    end
  end

  # GET /keywords/1
  # GET /keywords/1.json
  def show
    @keyword = Keyword.find(params[:id])
    
    drop_breadcrumb(@keyword.name, admin_keyword_path(@keyword))
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @keyword }
    end
  end

  # GET /keywords/new
  # GET /keywords/new.json
  def new
    @keyword = Keyword.new
    
    drop_breadcrumb('新增')
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @keyword }
    end
  end

  # GET /keywords/1/edit
  def edit
    @keyword = Keyword.find(params[:id])
    
    drop_breadcrumb(@keyword.name, admin_keyword_path(@keyword))
    drop_breadcrumb('修改')
    
  end

  # POST /keywords
  # POST /keywords.json
  def create
    @keyword = Keyword.new(keyword_params)
    @keyword.user_id = @current_user.uid
    @keyword.user_name = @current_user.name
    respond_to do |format|
      if @keyword.save
        format.html { redirect_to admin_keyword_path(@keyword), notice: '关键词创建成功.' }
        format.json { render json: @keyword, status: :created, location: @keyword }
      else
        format.html { render action: "new" }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /keywords/1
  # PATCH/PUT /keywords/1.json
  def update
    @keyword = Keyword.find(params[:id])

    respond_to do |format|
      if @keyword.update_attributes(keyword_params)
        format.html { redirect_to admin_keyword_path(@keyword), notice: '关键词修改成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /keywords/1
  # DELETE /keywords/1.json
  def destroy
    @keyword = Keyword.find(params[:id])
    @keyword.destroy

    respond_to do |format|
      format.html { redirect_to query_url(admin_keywords_url, Keyword, @current_user.uid) }
      format.json { head :no_content }
    end
  end

  private

    def keyword_params
      params.require(:keyword).permit(:addr, :name)
    end
    
    def init_breadcrumb_and_module_name
      set_query_url(Keyword, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("关键词", query_url(admin_keywords_url, Keyword, @current_user.uid))
      @_module_name = 'keyword'
      @__module_name = 'Keyword'
      @page_title = "关键词管理"
    end
end
