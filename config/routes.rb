Rails.application.routes.draw do
  scope :slack do
    # App setup url
    get 'setup' => 'commands#setup', as: :setup
    resources :webhooks, only: [:create]

    # Commands will be sent here
    resources :commands, only: [:create]

    # Handles the user oauth flow
    get 'login' => 'users#login', as: :login
    get 'oauth' => 'users#oauth', as: :oauth

    # Resolves meeting link
    get 'm/:id' => 'meetings#show', as: :meeting
  end
end
