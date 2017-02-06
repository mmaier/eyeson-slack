# Intercom service (gem not working)
module Intercom
  # Updater User IP
  class User
    def initialize(user, ip_address: nil)
      @user       = user
      @team       = user.team
      @ip_address = ip_address
      @uri = URI.parse('https://api.intercom.io/users')
      @existing_user = nil
      Thread.new do
        fetch_user!
        Intercom.request(uri, user_item)
      end
    end

    private

    def user_item
      { email: @user.email,
        name: @user.name,
        new_session: true, update_last_request_at: true,
        last_seen_ip: @ip_address,
        custom_attributes: custom_attributes }
    end

    def custom_attributes
      attributes = default_attributes
      unless @existing_user.present?
        attributes.merge!(
          first_login_source: default_attributes[:last_login_source],
          first_meeting_date: Time.now.to_i,
          first_meeting_info: default_attributes[:last_meeting_info]
        )
      end
      attributes
    end

    def default_attributes
      if @existing_user.present?
        counter = @existing_user[:custom_attributes][:count_slack]
      end
      counter ||= 0
      attributes = {
        last_login_source: 'Meeting Room',
        last_meeting_info: "Slack #{@team.name}",
        count_slack: counter.to_i + 1
      }
      attributes
    end

    def fetch_user!
      uri = @uri.dup
      uri.query = 'email={CGI.escape(@email)}'
      user = Intercom.get(uri)
      @existing_user = JSON.parse(user.to_s) if user.is_a?(Net::HTTPSuccess)
    end
  end

  def get(uri, params = {})
    req = Net::HTTP::Get.new(uri)
    request(req, uri, params)
  end
  module_function :get

  def post(uri, params = {})
    req = Net::HTTP::Post.new(uri)
    request(req, uri, params)
  end
  module_function :post

  def request(req, uri, params)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req['Content-Type'] = 'application/json'
    req['Accept'] = 'application/json'
    req.basic_auth(Rails.application.secrets.intercom_key,
                   Rails.application.secrets.intercom_secret)
    req.body = params.to_json
    http.request(req)
  end
  module_function :request
end
