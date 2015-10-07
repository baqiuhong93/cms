# encoding: utf-8
class Admin::NodesController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin_simple_no_top"
  
  # GET /nodes
  # GET /nodes.json
  def index
    respond_to do |format|
      format.html {
        if params[:subject].nil?
          render "index"
        else
          @search = Node.search(params[:search])
          @nodes = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).where("pId = -8").order('id DESC')
          render "subject"
        end
      }
      format.json {
        if !params[:q].nil? && params[:json_type] == 'all'
          render json: Node.select([:id, :name, :ancestry]).where("pId > -1 and name like '%#{params[:q]}%'").paginate(:page => params[:page], :per_page => params[:page_limit]).order('id DESC') and return
        elsif !params[:q].nil?
          render json: Node.select([:id, :name, :ancestry]).where("released = 1 and status > 0 and node_type = 2 and pId > -1 and name like '%#{params[:q]}%'").paginate(:page => params[:page], :per_page => params[:page_limit]).order('id DESC') and return
        else
          render json: Node.select([:id, :name, :pId, :node_type, :temp_node_id, :status]).where("pId > -1") 
        end 
      }
    end
  end

  # GET /nodes/1
  # GET /nodes/1.json
  def show
    @node = Node.find(params[:id])
    
    drop_breadcrumb(@node.name, admin_node_path(:id => @node.id, :subject => params[:subject]))
    respond_to do |format|
      format.html {
        
      }
      format.json {
        render json: @node
      }
    end
  end

  # GET /nodes/new
  # GET /nodes/new.json
  def new
    @node = Node.new :pId => params[:pId]

    drop_breadcrumb('新增')
    respond_to do |format|
      format.html { } # new.html.erb
      format.json { render json: @node }
    end
  end

  # GET /nodes/1/edit
  def edit
    @node = Node.find(params[:id])
    
    drop_breadcrumb(@node.name, admin_node_path(@node))
    drop_breadcrumb('修改')
  end

  # POST /nodes
  # POST /nodes.json
  def create
    
    if params[:node][:pId] == "0" || params[:node][:pId] == "-8"
      @node = Node.new(node_params)
    else
      parent_node = Node.find(params[:node][:pId])
      @node = parent_node.children.create node_params
    end
    
    @node.user = @current_user
    @node.user_name = @current_user.name

    #upload node page
    if !params[:temp_node_file].nil? && params[:temp_node_type] == "1"
      file_content = params[:temp_node_file].read
      jsp_path = @node.jsp_path
      FileUtils.mkpath GlobalSettings.jsp_upload_path + jsp_path[0...jsp_path.rindex("/")] unless File.exists?(GlobalSettings.jsp_upload_path + jsp_path[0...jsp_path.rindex("/")])
      File.open(GlobalSettings.jsp_upload_path + @node.jsp_temp_path, "wb") { |f| 
        f.write(add_jsp_define(file_content.gsub(/<%(.+?)%>/, '')))
      }
    end
    respond_to do |format|
      if @node.save!
        format.html {redirect_to admin_node_path(:id => @node.id, :subject => params[:subject]), notice: '栏目新建成功.'}
      else
        format.html { 
          render action: "new" 
        }
      end
    end
  end

  # PATCH/PUT /nodes/1
  # PATCH/PUT /nodes/1.json
  def update
    @node = Node.find(params[:id])
    respond_to do |format|
      #upload node page
      if !params[:temp_node_file].nil? && params[:temp_node_type] == "1"
        if !@node.down_code.nil? && !params[:temp_node_file].original_filename.include?(@node.down_code)
          flash[:notice] = "文件版本不正确!"
          format.html { render action: "edit" }
        end
        
        file_content = params[:temp_node_file].read
        _node_dir = GlobalSettings.jsp_upload_path + @node.jsp_path[0...@node.jsp_path.rindex("/")]
        FileUtils.mkpath _node_dir unless File.exists?(_node_dir)
        File.open(GlobalSettings.jsp_upload_path + @node.jsp_temp_path, "wb") { |f| 
          f.write(add_jsp_define(file_content.gsub(/<%(.+?)%>/, '')))
        }
        @node.temp_node_id = ''
        @node.status = 1
      end
      if @node.update_attributes(update_node_params)
        @node.generate_html if @node.released
        format.html { redirect_to admin_node_path(:id => @node.id, :subject => params[:subject]), notice: '栏目修改成功.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.json
  def destroy
    @node = Node.find(params[:id])

    respond_to do |format|
      format.json { 
        if @node.has_children?
          render json: {"status"  => 0, "msg"  =>  "请先删除子节点!"} and return
        end
        if @node.articles.count > 0
          render json: {"status"  => 0, "msg"  =>  "请先删除节点下的文章!"} and return
        end
        if @node.destroy
          if @node.list?
            _page_count = (@node.article_count % @node.per_page_size == 0) ? (@node.article_count/@node.per_page_size) : (@node.article_count/@node.per_page_size + 1)
            _page_count.times do |index|
              _node_path = @node.html_page_no_file.gsub("#pageNo", (index+1).to_s)
              File.delete(_node_path) if File.exists?(_node_path)
            end
          else
            _node_path = @node.html_page_no_file
            File.delete(_node_path) if File.exists?(_node_path)
          end
          render json: {"status"  => 1, "msg"  =>  "栏目删除成功!"} and return
        else
          render json: {"status"  => 0, "msg"  =>  "栏目删除失败!"} and return
        end
      }
    end
  end
  
  def released
    @node = Node.find(params[:id])
    origin_path = GlobalSettings.jsp_upload_path + @node.jsp_temp_path
    released_path = GlobalSettings.jsp_upload_path + @node.jsp_path
    FileUtils.mv origin_path, released_path if File.exists?(origin_path)
    @node.update_attributes({:released => true, :status => 2})
    @node.generate_html
    @node.delete_child_nodes_cache
    @node.purge_cache
    render json: {"status"  =>  1}
  end
  
  def released_articles
    _ids = []
    Article.where("released = 0 and ancestry like '%,#{params[:id]},%'").each do |article|
      article.generate_html(false)
      # 删除tag缓存
      article.tags.each do |tag|
        APP_CACHE.delete("taggable_#{tag.id.to_s}_Article")
      end
      
      _ids = _ids + article.ancestry.split(",")
    end
    @node = Node.find(params[:id])
    Article.where("released = 0 and ancestry like '%,#{params[:id]},%'").update_all({:status => 2, :released => true})
    @node.generate_html
    
    require 'net/http'
    Net::HTTP.get(URI.parse("#{GlobalSettings.cms_local_url}/cache/delete_list.jsp?ids=#{_ids.uniq.join(',')}")) unless _ids.empty?
    render json: {"status"  =>  1}
  end
  
  
  def view
    @node = Node.find(params[:id])
    redirect_to @node.preview_url
  end
  
  def down
    @node = Node.find(params[:id])
    down_code = SecureRandom.uuid.gsub("-","")
    @node.update_attribute(:down_code, down_code)
    if @node.view_url.present?
      if @node.released
        content = File.read(GlobalSettings.jsp_upload_path + @node.jsp_path).gsub(/<%(.+?)%>/, '')
      else
        content = File.read(GlobalSettings.jsp_upload_path + @node.jsp_temp_path).gsub(/<%(.+?)%>/, '')
      end
      send_data content, {:filename => "#{@node.name}-#{down_code}.html"}
    end
  end

  private

    def node_params
      params.require(:node).permit(:click, :keywords, :description, :domain_id, :node_type, :name, :pId, :per_page_size, :sortrank, :temp_article_id, :temp_node_id, :url, :unique_code, :node_type, :nav, :list_order_id, :article_url, :show_name)
    end
    
    def update_node_params
      params.require(:node).permit(:click, :keywords, :description, :name, :per_page_size, :sortrank, :temp_article_id, :temp_node_id, :unique_code, :nav, :list_order_id, :article_url, :show_name)
    end
    
    def init_breadcrumb_and_module_name
      #drop_breadcrumb(params[:subject].nil? ? "栏目" : "专题", admin_nodes_path(:subject => params[:subject]))
      drop_breadcrumb(params[:subject].nil? ? "栏目" : "专题", "javascript:void(0)")
      @_module_name = 'node'
      @__module_name = 'Node'
      @page_title = params[:subject].nil? ? "栏目管理" : "专题管理"
    end
end
