# encoding: utf-8
class Admin::ArticlesController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin_simple_no_top"
  
  
  def main
    render :layout => "admin_simple"
  end
  
  # GET /articles
  # GET /articles.json
  def index
    params[:search][:ancestry_contains] = ","+params[:search][:ancestry_contains]+"," if !params[:search].nil? && !params[:search][:ancestry_contains].empty?
    @search = Article.search(params[:search])
    @articles = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('id DESC')
     params[:search][:ancestry_contains] = params[:search][:ancestry_contains].gsub(",","") if !params[:search].nil? && !params[:search][:ancestry_contains].empty?
    
    respond_to do |format|
      format.html
      format.json { render json: @articles }
    end
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    @article = Article.find(params[:id])
  
    drop_breadcrumb(@article.title, admin_article_path(@article))
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @article }
    end
  end

  # GET /articles/new
  # GET /articles/new.json
  def new
    @article = Article.new(:writer => @current_user.name)
    @node = Node.where("id = ?", params[:node_id]).first unless params[:node_id].nil?
    @article.node_id = params[:node_id] if !@node.nil? && @node.list?
    
    @article_text = @article.build_article_text
    

    drop_breadcrumb('新增')
    
    respond_to do |format|
      format.html
      format.json { render json: @article }
    end
  end

  # GET /articles/1/edit
  def edit
    @article = Article.find(params[:id])
    
    drop_breadcrumb(@article.title, admin_article_path(@article))
    drop_breadcrumb('修改')
    
  end

  # POST /articles
  # POST /articles.json
  def create
    @article = Article.new(article_params)
    @article.user = @current_user
    @article.user_name = @current_user.name
    @node = Node.find(@article.node_id)
    @article.domain_id = @node.domain_id unless @node.nil?
    # upload image
    upload_hash = FileUploadUtil.uploadImage(params[:article][:img_path],"article")
    if upload_hash[:status] == 'error'
      respond_to do |format|
        flash[:notice] = upload_hash[:msg]
        format.html { render action: "new" }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
      return
    end
    @article.img_path = upload_hash[:file_name] unless params[:article][:img_path].nil?
    
    respond_to do |format|
      if @article.save!
        @article.update_attribute(:url, @node.article_url.gsub("#id", @article.id.to_s))
        @current_user.increment!(:today_article_count)
        format.html { redirect_to query_url(admin_articles_path, Article, @current_user.uid), notice: '文章新建成功.' }
        format.json { render json: @article, status: :created, location: @article }
      else
        format.html { render action: "new" }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1
  # PATCH/PUT /articles/1.json
  def update
    @article = Article.find(params[:id])
    @article.user = @current_user
    @article.user_name = @current_user.name
    
    upload_hash = FileUploadUtil.uploadImage(params[:article][:img_path], "article", @article.img_path)
    if upload_hash[:status] == 'error'
      respond_to do |format|
        flash[:notice] = upload_hash[:msg]
        format.html { render action: "new" }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
      return
    end

    @article.img_path = upload_hash[:file_name] unless params[:article][:img_path].nil?
    #@article.status = 1
    respond_to do |format|
      if @article.update_attributes(article_params)
        @article.generate_html if @article.released
        require 'net/http'
        Net::HTTP.get(URI.parse("#{GlobalSettings.cms_local_url}/cache/delete_list.jsp?ids=#{@article.ancestry}"))
        @article.purge_cache
        format.html { redirect_to query_url(admin_articles_path, Article, @current_user.uid), notice: '文章修改成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @article = Article.find(params[:id])
    @article.page_size.times do |t|
      _article_path = @article.html_page_no_file.gsub("#pageNo", (t+1).to_s)
      File.delete(_article_path) if File.exists?(_article_path)
    end
    require 'net/http'
    Net::HTTP.get(URI.parse("#{GlobalSettings.cms_local_url}/cache/delete_list.jsp?ids=#{@article.ancestry}"))
    @article.purge_cache
    @article.destroy

    respond_to do |format|
      format.html { redirect_to query_url(admin_articles_path, Article, @current_user.uid), notice: "文章删除成功!" }
      format.json { head :no_content }
    end
  end
  
  def batch_destroy
    params[:ids].split(",").each do |id|
      @article = Article.where("id = ?", id).first
      @article.page_size.times do |t|
        _article_path = @article.html_page_no_file.gsub("#pageNo", (t+1).to_s)
        File.delete(_article_path) if File.exists?(_article_path)
      end unless @article.nil?
      require 'net/http'
      Net::HTTP.get(URI.parse("#{GlobalSettings.cms_local_url}/cache/delete_list.jsp?ids=#{@article.ancestry}"))
      @article.purge_cache
      @article.destroy unless @article.nil?
    end unless params[:ids].nil?
    render :json => {"status" => 1}
  end
  
  def released
    @article = Article.find(params[:id])
    @article.update_status_and_reseased
    @article.generate_html
    @article.purge_cache
    require 'net/http'
    Net::HTTP.get(URI.parse("#{GlobalSettings.cms_local_url}/cache/delete_list.jsp?ids=#{@article.ancestry}"))
    render json: {"status"  =>  1}
  end
  
  def batch_released
    if params[:ids].nil?
      render json: {"status"  =>  0}
    else
      _ids = []
      params[:ids].split(",").each do |article_id|
        @article = Article.find(article_id)
        @article.update_status_and_reseased
        @article.generate_html
        @article.purge_cache
        _ids = _ids + @article.ancestry.split(",")
      end
      
      require 'net/http'
      Net::HTTP.get(URI.parse("#{GlobalSettings.cms_local_url}/cache/delete_list.jsp?ids=#{_ids.uniq.join(',')}")) unless _ids.empty?
      render json: {"status"  =>  1}
    end
  end
  
  def view
    @article = Article.find(params[:id])
    redirect_to @article.preview_url
  end

  private

    def article_params
      params.require(:article).permit(:node_id, :click, :commend, :description, :origin_id, :page_size, :released, :released_at, :created_at, :short_title, :sortrank, :sub_node_ids, :sub_title, :title, :url, :writer, :tag_list, :seo_keyword, :seo_description, :article_text_attributes => [:content])
    end
    
    def init_breadcrumb_and_module_name
      set_query_url(Article, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("文章", query_url(admin_articles_path, Article, @current_user.uid))
      @_module_name = 'article'
      @__module_name = 'Article'
      @page_title = "文章管理"
    end

end
