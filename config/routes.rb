Rails.application.routes.draw do
	post 'commands' => 'commands#execute', :defaults => {format: :json}
end
