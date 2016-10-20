Rails.application.routes.draw do
	# Commands will be sent here
	post 'commands' => 'commands#execute', :defaults => {format: :json}

	# Handles the user oauth flow
	get 'login' => 'users#login', as: :login
	get 'oauth' => 'users#oauth', as: :oauth
	get 'error' => 'users#error', as: :error

	# Resolves meeting link
	get 'meetings/:id' => 'meetings#show', as: :meeting
end
