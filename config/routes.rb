Rails.application.routes.draw do
  root 'home#index'

  get 'thankyou' => 'home#thankyou'
  resources :users, only: [:new, :edit] do
    collection do
      post :subscribe
      patch :unsubscribe
    end
  end
end
