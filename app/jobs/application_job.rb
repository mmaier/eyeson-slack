class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  protected

  def default_url_options
    Rails.application.routes.default_url_options
    end
end
