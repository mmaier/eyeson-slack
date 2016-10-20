Rails.application.routes.draw do
	# Commands will be sent here
	post 'commands' => 'commands#execute', :defaults => {format: :json}

	# Handles the user oauth flow
	get 'login' => 'users#login', as: :login
	get 'oauth' => 'users#oauth', as: :oauth

	# Resolves meeting link
	get 'm/:id' => 'meetings#show', as: :meeting
end
