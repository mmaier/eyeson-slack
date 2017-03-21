require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
# require "active_record/railtie"
require 'action_controller/railtie'
# require "action_mailer/railtie"
require 'action_view/railtie'
require 'action_cable/engine'
# require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Slack
  # Main App
  class Application < Rails::Application
    # config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.api_only = true
    config.services = config_for(:services)
    config.action_dispatch.trusted_proxies = /
    ^127\.0\.0\.1$                | # localhost IPv4
    ^::1$                         | # localhost IPv6
    ^fc00:                        | # private IPv6 range fc00
    ^10\.                         | # private IPv4 range 10.x.x.x
    ^213.208.148.[1-9]+$          |
    ^213.208.129.[1-9]+$          |
    ^2a01:190:1700:14(\h|:)+$     |
    ^172\.(1[6-9]|2[0-9]|3[0-1])\.  # private IPv4 range
    /x

    Eyeson.configure do |config|
      config.api_endpoint      = Rails.configuration.services['eyeson_api']
      config.account_endpoint  = Rails.configuration
                                      .services['eyeson_account_api']
      config.account_api_key   = Rails.application.secrets.accounts_api_key
      config.internal_username = Rails.application.secrets.internal_api_username
      config.internal_password = Rails.application.secrets.internal_api_password
    end
  end
end
