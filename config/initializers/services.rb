module Api
  # Application
  class Application < Rails::Application
    config.services = config_for(:services)
  end
end
