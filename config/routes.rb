Rails.application.routes.draw do
  root 'users#new'
  resources :users, only: [:new] do
    collection do
      post :subscribe
      get :unsubscribe
    end
  end
end
