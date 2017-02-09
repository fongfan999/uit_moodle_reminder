Rails.application.routes.draw do
  root 'users#new'
  resources :users, only: [:new] do
    collection do
      post :subscribe
    end
  end

  get '/unsubscribe', to: "users#unsubscribe"
  get '/unsubscribe_event', to: "users#unsubscribe_event"
  
  mount Facebook::Messenger::Server, at: 'bot'
end
