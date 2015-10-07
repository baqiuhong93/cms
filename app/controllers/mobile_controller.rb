# encoding: utf-8
class MobileController < ApplicationController
	layout "front"

	VIDEO_TEMPLATE_IDS = ["2143"]

	def index
		@kaoshizixuns = Article.where("status = 2 and released = true and ancestry like '%,3362,%'").order("commend DESC,id desc").limit(4)
		@beikaoziliaos = Article.where("status = 2 and released = true and ancestry like '%,3366,%'").order("commend DESC,id desc").limit(4)
		@mianfeishipins = Article.where("status = 2 and released = true and (ancestry like '%,2143,%')").order("commend DESC,id desc").limit(4)
	end

	def sp
	end

	def huizong
		@node = Node.where("id = ?", params[:id].to_i).first
		if VIDEO_TEMPLATE_IDS.include?(params[:id])
			render "huizong_video"
		else	
			render "huizong_default"
		end
	end

	def list
		@node = Node.where("id = ?", params[:id].to_i).first
		@articles = @node.articles.where("status = 2 and released = true").paginate(:page => params[:page], :per_page => 10).order('commend DESC,id DESC')
		if VIDEO_TEMPLATE_IDS.include?(@node.parent.id.to_s)
			render "list_video"
		else	
			render "list"
		end
	end

	def show
		@article = Article.where("id = ?", params[:id]).first
		@article.increment!(:click)
		if VIDEO_TEMPLATE_IDS.include?(@article.node.parent.id.to_s)
			render "show_video"
		else	
			render "show"
		end
	end

	def fenxiao
		render :layout => false
	end
end