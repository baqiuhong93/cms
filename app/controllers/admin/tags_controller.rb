# encoding: utf-8
class Admin::TagsController < ApplicationController
  before_filter :login_required
  authorize_resource :class => false
  
  def index
    tags = ActsAsTaggableOn::Tag.select([:id, :name]).where("name like '%#{params[:q]}%'").paginate(:page => params[:page], :per_page => params[:page_limit]).order('id DESC')
    render :json => tags
  end
  
  def create
    tag = ActsAsTaggableOn::Tag.new(:name => params[:tag_name])
    if tag.save
      render :json => {"status" => 1, "tag" => tag}
    else
      render :json => {"status" => 0}
    end
  end
end
