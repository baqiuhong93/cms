# encoding: utf-8
class Admin::HtmlTemplatesController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin"
  
  # GET /templates
  # GET /templates.json
  def index
    @search = HtmlTemplate.search(params[:search])
    @html_templates = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('id DESC')
    if !params[:type_id].nil?
      @html_templates = @html_templates.where("type_id = ?", params[:type_id])
    end
    if !params[:q].nil?
      @html_templates = @html_templates.where("name like '%#{params[:q]}%'")
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @html_templates }
    end
  end

  # GET /templates/1
  # GET /templates/1.json
  def show
    @html_template = HtmlTemplate.find(params[:id])

    drop_breadcrumb(@html_template.name, admin_html_template_path(@html_template))
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @html_template }
    end
  end

  # GET /templates/new
  # GET /templates/new.json
  def new
    @html_template = HtmlTemplate.new

    drop_breadcrumb('新增')
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @html_template }
    end
  end

  # GET /templates/1/edit
  def edit
    @html_template = HtmlTemplate.find(params[:id])
    
    drop_breadcrumb(@html_template.name, admin_html_template_path(@html_template))
    drop_breadcrumb('修改')
  end

  # POST /templates
  # POST /templates.json
  def create
    @html_template = HtmlTemplate.new(html_template_params)
    @html_template.user = @current_user
    @html_template.user_name = @current_user.name
    
    respond_to do |format|
      if @html_template.save
        #upload node page
        if !params[:upload_path_file].nil?
          file_content = params[:upload_path_file].read
          FileUtils.mkpath GlobalSettings.jsp_upload_path + @html_template.jsp_dir unless File.exists?(GlobalSettings.jsp_upload_path + @html_template.jsp_dir)
          if @html_template.type_id == 3
            File.open(GlobalSettings.jsp_upload_path + @html_template.jsp_temp_path, "wb") { |f| @html_template.mobanpianduan? ? f.write(file_content.gsub(/<%(.+?)%>/, '')) : f.write(add_article_jsp_define(file_content.gsub(/<%(.+?)%>/, '')))}
          else
            File.open(GlobalSettings.jsp_upload_path + @html_template.jsp_temp_path, "wb") { |f| @html_template.mobanpianduan? ? f.write(file_content.gsub(/<%(.+?)%>/, '')) : f.write(add_jsp_define(file_content.gsub(/<%(.+?)%>/, '')))}
          end
        end
        
        format.html { redirect_to admin_html_template_path(@html_template), notice: '模板创建成功.' }
        format.json { render json: @html_template, status: :created, location: @html_template }
      else
        format.html { render action: "new" }
        format.json { render json: @html_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /templates/1
  # PATCH/PUT /templates/1.json
  def update
    @html_template = HtmlTemplate.find(params[:id])
    @html_template.user = @current_user
    @html_template.user_name = @current_user.name
    
    #upload node page
    if !params[:upload_path_file].nil?
      if !@html_template.down_code.nil? && !params[:upload_path_file].original_filename.include?(@html_template.down_code)
        flash[:notice] = "文件版本不正确!"
        format.html { render action: "edit" }
      end
      file_content = params[:upload_path_file].read
      FileUtils.mkpath GlobalSettings.jsp_upload_path + @html_template.jsp_dir unless File.exists?(GlobalSettings.jsp_upload_path + @html_template.jsp_dir)
      if @html_template.type_id == 3
        File.open(GlobalSettings.jsp_upload_path + @html_template.jsp_temp_path, "wb") { |f| @html_template.mobanpianduan? ? f.write(file_content.gsub(/<%(.+?)%>/, '')) : f.write(add_article_jsp_define(file_content.gsub(/<%(.+?)%>/, '')))}
      else
        File.open(GlobalSettings.jsp_upload_path + @html_template.jsp_temp_path, "wb") { |f| @html_template.mobanpianduan? ? f.write(file_content.gsub(/<%(.+?)%>/, '')) : f.write(add_jsp_define(file_content.gsub(/<%(.+?)%>/, '')))}
      end
      @html_template.status = 1
    end
    
    respond_to do |format|
      if @html_template.update_attributes(html_template_params)
        format.html { redirect_to query_url(admin_html_templates_path, HtmlTemplate, @current_user.uid), notice: '模板修改成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @html_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /templates/1
  # DELETE /templates/1.json
  def destroy
    @html_template = HtmlTemplate.find(params[:id])
    if @html_template.nodes.count == 0 && @html_template.articles.count == 0
      @html_template.destroy
      notice = "模板删除成功!"
    else
      notice = "模板已被引用，无法删除!"
    end

    respond_to do |format|
      format.html { redirect_to query_url(admin_html_templates_path, HtmlTemplate, @current_user.uid), notice: notice }
      format.json { head :no_content }
    end
  end
  
  
  def down
    @html_template = HtmlTemplate.find(params[:id])
    down_code = SecureRandom.uuid.gsub("-","")
    @html_template.update_attribute(:down_code, down_code)
    if @html_template.released
      content = File.read(GlobalSettings.jsp_upload_path + @html_template.jsp_path).gsub(/<%(.+?)%>/, '')
    else
      content = File.read(GlobalSettings.jsp_upload_path + @html_template.jsp_temp_path).gsub(/<%(.+?)%>/, '')
    end
    send_data content, {:filename => "#{@html_template.name}-#{down_code}.html"}
  end
  
  def released
    @html_template = HtmlTemplate.find(params[:id])
    origin_path = GlobalSettings.jsp_upload_path + @html_template.jsp_temp_path
    released_path = GlobalSettings.jsp_upload_path + @html_template.jsp_path
    FileUtils.mv origin_path, released_path if File.exists?(origin_path)
    @html_template.update_attributes({:status => 2, :released => true})
    Node.where("released = true and temp_node_id = ?", params[:id]).each do |node|
      node.generate_html
    end
    Node.where("released = true and temp_article_id = ?", params[:id]).each do |node|
      node.articles.where("released = true").each do |article|
        article.generate_html
      end
    end
    render :json =>  {"status"  =>  1}
  end

  private

    def html_template_params
      params.require(:html_template).permit(:name, :type_id)
    end
    
    def init_breadcrumb_and_module_name
      set_query_url(HtmlTemplate, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("模板", query_url(admin_html_templates_path, HtmlTemplate, @current_user.uid))
      @_module_name = 'html_template'
      @__module_name = 'HtmlTemplate'
      @page_title = "模板管理"
    end
end
