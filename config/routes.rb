Rails.application.routes.draw do
  resources :users, only: [:index, :new, :create, :show] do
    scope module: :users do
      resource :confirmation, only: [:create] do
        post 'accept' => 'confirmations#accept'
      end
    end
  end
end
