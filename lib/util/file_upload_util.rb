# encoding: utf-8

class FileUploadUtil
  
  
  def self.image_clip_path(image_path, clips_type)
    if image_path.nil? ||  clips_type.nil? || image_path.split('_').length != 3 || image_path.split('.').length != 2
      return '/empty.gif'
    end
    
    return GlobalSettings.upload_view_url + image_path[0..image_path.rindex("/")] +  clips_type + "/" + image_path[image_path.rindex("/")+1, image_path.length]
  end
  
  def self.uploadImage(file_object,module_name,file_name=nil)
    if file_object.nil? || file_object.original_filename.nil? || module_name.nil?
      return {}
    end
    
    filename_arr = file_object.original_filename.downcase.split('.')
    if filename_arr.size < 2
      return {:status => 'error', :msg => '文件名不正确！'}
    end
    
    if ['jpg','gif','png'].index(filename_arr[filename_arr.size-1]).nil?
      return {:status => 'error', :msg => '文件格式不正确！'}
    end

    imageMagick = Magick::Image.from_blob(file_object.read).first
    
    if !GlobalSettings.image_types.include?(imageMagick.mime_type.strip)
      return {:status => 'error', :msg => '文件格式不正确！'}
    end
    
    
    file_size = imageMagick.filesize
    if file_size > GlobalSettings.upload_file_size
      return {:status => 'error', :msg => '文件大小超过5M！'}
    end
    
    if file_name.nil? || file_name.split('_').length != 3 || file_name.split('.').length != 2
      upload_dir = ["", module_name, DateTime.now.strftime('%Y/%m/%d/')].join('/')
      FileUtils.mkpath GlobalSettings.upload_path+upload_dir unless File.exists?(GlobalSettings.upload_path+upload_dir)
      file_name = SecureRandom.uuid.to_s.gsub(/-/,'') + '_' + imageMagick.columns.to_s + '_' + imageMagick.rows.to_s + '.' + filename_arr[filename_arr.size-1]
      
    else
      upload_dir = file_name[0..file_name.rindex("/")]
      file_name = file_name[file_name.rindex("/")+1,file_name.length]
        # delete old upload file start
      GlobalSettings[module_name.to_sym].each_key do |key|
        v_f = GlobalSettings.upload_path + upload_dir + key + "/" + file_name
        File.delete(v_f) if File.exists?(v_f)
      end unless GlobalSettings[module_name.to_sym].nil?
      File.delete(GlobalSettings.upload_path+upload_dir+"/"+file_name) if File.exists?(GlobalSettings.upload_path+upload_dir+"/"+file_name)
      # delete old upload file end
      file_name = file_name.split('_')[0]  + '_' + imageMagick.columns.to_s + '_' + imageMagick.rows.to_s + '.' + filename_arr[filename_arr.size-1]
    end
    imageMagick.write(GlobalSettings.upload_path+upload_dir+file_name)
		
    
    return {:status => 'success', :msg => '文件上传成功！', :file_size => file_size, :file_name => upload_dir+file_name}
  end
  
end
