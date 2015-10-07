# encoding: utf-8
class Admin::MessageTablesController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  before_filter :init_breadcrumb_and_module_name
  layout "admin"
  
  # GET /message_tables
  # GET /message_tables.json
  def index
    @search = MessageTable.search(params[:search])
    @message_tables = @search.paginate(:page => params[:page], :per_page => GlobalSettings.per_page).order('id DESC')
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @message_tables }
    end
  end

  # GET /message_tables/1
  # GET /message_tables/1.json
  def show
    @message_table = MessageTable.find(params[:id])
    
    drop_breadcrumb(@message_table.name, admin_message_table_path(@message_table))

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @message_table }
    end
  end

  # GET /message_tables/new
  # GET /message_tables/new.json
  def new
    @message_table = MessageTable.new
    drop_breadcrumb('新增')
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @message_table }
    end
  end

  # GET /message_tables/1/edit
  def edit
    @message_table = MessageTable.find(params[:id])
    
    drop_breadcrumb(@message_table.name, admin_message_table_path(@message_table))
    drop_breadcrumb('修改')
  end

  # POST /message_tables
  # POST /message_tables.json
  def create
    @message_table = MessageTable.new(message_table_params)
    @message_table.user_id = @current_user.uid
    @message_table.user_name = @current_user.name
    respond_to do |format|
      if @message_table.save
        format.html { redirect_to admin_message_table_path(@message_table), notice: '信息表创建成功.' }
        format.json { render json: @message_table, status: :created, location: @message_table }
      else
        format.html { render action: "new" }
        format.json { render json: @message_table.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /message_tables/1
  # PATCH/PUT /message_tables/1.json
  def update
    @message_table = MessageTable.find(params[:id])

    respond_to do |format|
      if @message_table.update_attributes(message_table_params)
        format.html { redirect_to admin_message_table_path(@message_table), notice: '信息表修改成功.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @message_table.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /message_tables/1
  # DELETE /message_tables/1.json
  def destroy
    @message_table = MessageTable.find(params[:id])
    MessageText.where(:message_table_id => @message_table.id).destroy
    @message_table.destroy
    redirect_to query_url(admin_message_tables_path, MessageTable, @current_user.uid)
  end
  
  
  def new_column
    @message_table = MessageTable.find(params[:id])
    
    drop_breadcrumb(@message_table.name, admin_message_table_path(@message_table))
    drop_breadcrumb('新增列')
    10.times do
      @message_table.message_columns.build
    end
  end
  
  def create_columns
    @message_table = MessageTable.find(params[:id])
    
    @message_table.message_columns_attributes = params[:message_table][:message_columns_attributes]
    
    #params.require(:message_table).permit(:message_columns_attributes => [:id, :name, :column_name, :show_index, :export, :sortrank, :type_id, :json_value, :default_value, :_destroy])
    @message_table.save()
    redirect_to admin_message_tables_path
  end
  
  def index_text
    @message_table = MessageTable.find(params[:id])
    @message_texts = MessageText.where(message_table_id: @message_table.id)
    @message_table.message_columns.each do |message_column|
      if message_column.query
        if params[message_column.column_name.to_sym].present?
          if message_column.type_id == 1 || message_column.type_id == 5
            @message_texts = @message_texts.where("text.#{message_column.column_name}".to_sym => /#{params[message_column.column_name.to_sym]}/)
          elsif message_column.type_id == 3
            @message_texts = @message_texts.in("text.#{message_column.column_name}".to_sym => params[message_column.column_name.to_sym])
          else
            @message_texts = @message_texts.where("text.#{message_column.column_name}".to_sym => params[message_column.column_name.to_sym])
          end
        end
      end
    end
    @message_texts = @message_texts.desc(:created_at)
    drop_breadcrumb(@message_table.name, admin_message_table_path(@message_table))
    drop_breadcrumb('数据')
    respond_to do |format|
      format.html {
        set_query_url(MessageText, @current_user.uid)
        @message_texts = @message_texts.paginate(:page => params[:page], :per_page => GlobalSettings.per_page)
      }
      format.xls
    end
  end
  
  def show_text
    @message_table = MessageTable.find(params[:id])
    @message_text = MessageText.find(params[:text_id])
    drop_breadcrumb(@message_table.name, admin_message_table_path(@message_table))
    drop_breadcrumb('数据', query_url(index_text_admin_message_table_path(@message_table), MessageText, @current_user.uid))
    drop_breadcrumb(@message_text._id)
  end
  
  def edit_text
    @message_table = MessageTable.find(params[:id])
    @message_text = MessageText.find(params[:text_id])
    drop_breadcrumb(@message_table.name, admin_message_table_path(@message_table))
    drop_breadcrumb('数据', query_url(index_text_admin_message_table_path(@message_table), MessageText, @current_user.uid))
    drop_breadcrumb(@message_text._id, show_text_admin_message_table_path(:id => @message_table, :text_id => @message_text._id))
    drop_breadcrumb('修改')
  end
  
  def update_text
    @message_table = MessageTable.find(params[:id])
    @message_text = MessageText.find(params[:text_id])
    @message_table.message_columns.each do |message_column|
      if message_column.edit
        if params[message_column.column_name.to_sym].nil?
          @message_text.text[message_column.column_name] = message_column.type_id == 3 ? [] : ''
        else
          @message_text.text[message_column.column_name] = params[message_column.column_name.to_sym]
        end
      end
    end
    @message_text.update_attributes(text: @message_text.text)
    render json: {"status"  => "sucess", "msg"  =>  "数据修改成功!"}
  end
  
  def destroy_text
    @message_table = MessageTable.find(params[:id])
    @message_text = MessageText.find(params[:text_id])
    @message_text.destroy

    respond_to do |format|
      format.html { redirect_to query_url(index_text_admin_message_table_path(@message_table), MessageText, @current_user.uid) }
      format.json { head :no_content }
    end
  end

  private

    def message_table_params
      params.require(:message_table).permit(:description, :end_at, :logined, :name, :start_at, :table_name)
    end
    
    def init_breadcrumb_and_module_name
      set_query_url(MessageTable, @current_user.uid) if params[:action] == "index"
      drop_breadcrumb("信息表", query_url(admin_message_tables_path, MessageTable, @current_user.uid))
      @_module_name = 'message_table'
      @__module_name = 'MessageTable'
      @page_title = "信息表管理"
    end
end
