namespace :articles do
    task :released => :environment do
      Article.where("status = 3 and released_at <= ?", DateTime.now).each do |article|
        puts article.id
      end
    end
end
