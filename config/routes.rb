Rails.application.routes.draw do
  scope :slack do
    # App setup
    get 'setup' => 'teams#setup', as: :setup
    get 'setup/complete' => 'teams#create', as: :setup_complete

    # Commands will be sent here
    resources :commands, only: [:create]
    resources :webhooks, only: [:create]
    resources :recordings, only: [:show]

    # Handles the user oauth flow
    get 'login' => 'users#login', as: :login
    get 'oauth' => 'users#oauth', as: :oauth

    # Resolves meeting link
    get 'm/:id' => 'meetings#show', as: :meeting
    get 'w/:id' => 'meetings#show', as: :webinar

    root 'teams#setup'
  end

  root 'teams#setup'
end
