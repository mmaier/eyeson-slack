# Manages conf rooms
class Room

  class ValidationFailed < StandardError
  end

  attr_reader :url

  def initialize(channel: {}, user: {})
    @team    = channel.team
    @channel = channel
    @user    = user
    @url     = nil
    @config  = Rails.configuration.services
    create!
  end

  private

  def create!
    room = post('/rooms', id:   @channel.external_id,
                          name: @channel.name,
                          user: mapped_user)
    
    raise ValidationFailed.new(room['error']) if room['error'].present?
    @url = room['links']['gui']
  end

  def post(path, params = {})
    uri = URI.parse("#{@config['eyeson_api']}#{path}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = @team.api_key
    req.body = params.to_json

    res = http.request(req)
    JSON.parse(res.body)
  end

  def mapped_user
    {
      id:     @user.external_id,
      name:   @user.name,
      avatar: @user.avatar
    }
  end
end
