Rails.application.routes.draw do
  root 'users#new'
  
  resources :users, only: [:new, :edit] do
    collection do
      post :subscribe
      patch :unsubscribe
    end
  end
end
