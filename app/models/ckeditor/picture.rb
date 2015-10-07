class Ckeditor::Picture < Ckeditor::Asset
  has_attached_file :data,
                    #:url  => "/ckeditor_assets/pictures/:id/:style_:basename.:extension",
                    #:path => ":rails_root/public/ckeditor_assets/pictures/:id/:style_:basename.:extension",
                    :url  => "#{GlobalSettings.upload_view_url}/ckeditor_assets/pictures/:id/:style_:basename.:extension",
                    :path => "#{GlobalSettings.upload_path}/ckeditor_assets/pictures/:id/:style_:basename.:extension",
                    :styles => { :content => '800>', :thumb => '118x100#' }

  validates_attachment_size :data, :less_than => 2.megabytes
  validates_attachment_presence :data

  def url_content
    url(:content)
  end
end
