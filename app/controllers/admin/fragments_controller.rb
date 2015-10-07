# encoding: utf-8
class Admin::FragmentsController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin"
  
  # GET /fragments
  # GET /fragments.json
  def index
    @search = Fragment.search(params[:search])
    @fragments = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('id DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @fragments }
    end
  end

  # GET /fragments/1
  # GET /fragments/1.json
  def show
    @fragment = Fragment.find(params[:id])
    
    drop_breadcrumb(@fragment.title, admin_fragment_path(@fragment))
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @fragment }
    end
  end

  # GET /fragments/new
  # GET /fragments/new.json
  def new
    @fragment = Fragment.new

    drop_breadcrumb('新增')
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @fragment }
    end
  end

  # GET /fragments/1/edit
  def edit
    @fragment = Fragment.find(params[:id])
    
    drop_breadcrumb(@fragment.title, admin_fragment_path(@fragment))
    drop_breadcrumb('修改')
  end

  # POST /fragments
  # POST /fragments.json
  def create
    @fragment = Fragment.new(fragment_params)
    @fragment.user = @current_user
    @fragment.user_name = @current_user.name
    respond_to do |format|
      if @fragment.save
        format.html { redirect_to admin_fragment_path(@fragment), notice: '片段创建成功.' }
        format.json { render json: @fragment, status: :created, location: @fragment }
      else
        format.html { render action: "new" }
        format.json { render json: @fragment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fragments/1
  # PATCH/PUT /fragments/1.json
  def update
    @fragment = Fragment.find(params[:id])
    @fragment.user = @current_user
    @fragment.user_name = @current_user.name
    respond_to do |format|
      if @fragment.update_attributes(fragment_params)
        format.html { redirect_to admin_fragment_path(@fragment), notice: '片段修改成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @fragment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fragments/1
  # DELETE /fragments/1.json
  def destroy
    @fragment = Fragment.find(params[:id])
    @fragment.destroy

    respond_to do |format|
      format.html { redirect_to query_url(admin_fragments_path, Fragment, @current_user.uid) }
      format.json { head :no_content }
    end
  end

  private

    def fragment_params
      params.require(:fragment).permit(:content, :title, :type_id, :unique_code)
    end
    
    def init_breadcrumb_and_module_name
      set_query_url(Fragment, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("片段", query_url(admin_fragments_path, Fragment, @current_user.uid))
      @_module_name = 'fragment'
      @__module_name = 'Fragment'
      @page_title = "片段管理"
    end
end
