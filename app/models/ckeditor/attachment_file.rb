class Ckeditor::AttachmentFile < Ckeditor::Asset
  has_attached_file :data,
                    :url => "#{GlobalSettings.upload_view_url}/ckeditor_assets/attachments/:id/:filename",
                    :path => "#{GlobalSettings.upload_path}/ckeditor_assets/attachments/:id/:filename"
                    #:url => "/ckeditor_assets/attachments/:id/:filename",
                    #:path => ":rails_root/public/ckeditor_assets/attachments/:id/:filename"
  
  validates_attachment_size :data, :less_than => 10.megabytes
  validates_attachment_presence :data

  def url_thumb
    @url_thumb ||= Ckeditor::Utils.filethumb(filename)
  end
end
