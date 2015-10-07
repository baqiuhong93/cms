Cms::Application.routes.draw do
  
  mount Ckeditor::Engine => "/ckeditor"
  
  namespace :admin do
    root :to => "home#index"
    resources :nodes do
      post 'released', :on => :collection
      post 'released_articles', :on => :collection
      get 'view', :on => :member
      get 'down', :on => :member
    end
    resources :articles do
      post 'released', :on => :collection
      post 'batch_released', :on => :collection
      post 'batch_destroy', :on => :collection
      get 'tag', :on => :collection
      get 'view', :on => :member
      get 'main', :on => :collection
    end
    resources :message_tables do
      get 'new_column', :on => :member
      post 'create_columns', :on => :member
      get 'index_text', :on => :member
      get 'show_text', :on => :member
      get 'edit_text', :on => :member
      post 'update_text', :on => :member
      delete 'destroy_text', :on => :member
    end
    resources :domains, :subjects, :friend_links
    resources :tags, :only => [:index, :create]
    resources :keywords
    resources :origins
    resources :users, :only => [:index, :show]
    resources :html_templates do
      get 'down', :on => :member
      post 'released', :on => :member
    end
    resources :fragments
  end
    
  resources :message_tables, :only => [:index]
  match '/message_tables/create', :to => 'message_tables#create', :via => :GET
  
  # omniauth
  match '/auth/:provider/callback', :to => 'user_sessions#create'
  match '/auth/failure', :to => 'user_sessions#failure'

  # Custom logout
  match '/logout', :to => 'user_sessions#destroy'

  match ':controller(/:action(/:id))(.:format)'
end
