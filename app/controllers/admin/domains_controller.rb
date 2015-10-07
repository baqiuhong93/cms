# encoding: utf-8
class Admin::DomainsController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin"
  
  # GET /domains
  # GET /domains.json
  def index
    @search = Domain.search(params[:search])
    @domains = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('id DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @domains }
    end
  end

  # GET /domains/1
  # GET /domains/1.json
  def show
    @domain = Domain.find(params[:id])
    
    drop_breadcrumb(@domain.name, admin_domain_path(@domain))
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @domain }
    end
  end

  # GET /domains/new
  # GET /domains/new.json
  def new
    @domain = Domain.new
    
    drop_breadcrumb('新增')
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @domain }
    end
  end

  # GET /domains/1/edit
  def edit
    @domain = Domain.find(params[:id])
    
    drop_breadcrumb(@domain.name, admin_domain_path(@domain))
    drop_breadcrumb('修改')
  end

  # POST /domains
  # POST /domains.json
  def create
    @domain = Domain.new(domain_params)
    @domain.user_id = @current_user.uid
    @domain.user_name = @current_user.name
    respond_to do |format|
      if @domain.save
        format.html { redirect_to admin_domain_path(@domain), notice: '域名创建成功.' }
        format.json { render json: @domain, status: :created, location: @domain }
      else
        format.html { render action: "new" }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /domains/1
  # PATCH/PUT /domains/1.json
  def update
    @domain = Domain.find(params[:id])

    respond_to do |format|
      if @domain.update_attributes(domain_params)
        format.html { redirect_to admin_domain_path(@domain), notice: '域名更新成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /domains/1
  # DELETE /domains/1.json
  def destroy
    @domain = Domain.find(params[:id])
    if @domain.nodes.count == 0
      @domain.destroy
      notice = "域名删除成功!"
    else
      notice = "域名已被引用，无法删除!"
    end

    respond_to do |format|
      format.html { redirect_to query_url(admin_domains_path, Domain, @current_user.uid), notice: notice }
      format.json { head :no_content }
    end
  end

  private

    def domain_params
      params.require(:domain).permit(:addr, :name)
    end
    
    def init_breadcrumb_and_module_name
      set_query_url(Domain, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("域名", query_url(admin_domains_path, Domain, @current_user.uid))
      @_module_name = 'domain'
      @__module_name = 'Domain'
      @page_title = "域名管理"
    end
end
