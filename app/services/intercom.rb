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
      save!
    end

    private

    def save!
      Thread.new do
        fetch_user!
        Intercom.post(@uri, user_item)
      end
    end

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
          first_meeting_at: Time.now.to_i,
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
      uri.query = "email=#{CGI.escape(@user.email)}"
      user = Intercom.get(uri)
      @existing_user = JSON.parse(user.body) if user.is_a?(Net::HTTPSuccess)
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
    req['Authorization'] = "Basic #{access_token}"
    req.body = params.to_json
    http.request(req)
  end
  module_function :request

  def access_token
    Base64.urlsafe_encode64(
      Rails.application.secrets.intercom_secret
    )
  end
  module_function :access_token
end
