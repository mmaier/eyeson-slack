Rails.application.routes.draw do
  scope :slack do
    # App setup url
    get 'setup' => 'users#setup', as: :setup

    # Commands will be sent here
    post 'commands' => 'commands#respond', :defaults => { format: :json }

    # Handles the user oauth flow
    get 'login' => 'users#login', as: :login
    get 'oauth' => 'users#oauth', as: :oauth

    # Resolves meeting link
    get 'm/:id' => 'meetings#show', as: :meeting
  end
end
