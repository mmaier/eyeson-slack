# Intercom service (gem not working)
module Intercom
  # Updater User IP
  class User
    def initialize(user, ip_address: nil)
      return unless Rails.env.production?
      @email = user.email
      @ip_address = ip_address
      uri = URI.parse('https://api.intercom.io/users')
      Intercom.request(uri, user_item)
    end

    private

    def user_item
      {
        email: @email,
        last_seen_ip: @ip_address
      }
    end
  end

  def request(uri, params)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Accept'] = 'application/json'
    req.basic_auth(Rails.application.secrets.intercom_key,
                   Rails.application.secrets.intercom_secret)
    req.body = params.to_json
    http.request(req)
  end
  module_function :request
end
