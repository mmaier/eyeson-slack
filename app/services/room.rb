# Manages conf rooms
class Room
  attr_reader :url, :error

  def initialize(channel: {}, user: {})
    @channel = channel
    @user    = user
    @url     = nil
    @error   = nil
    create!
  end

  private

  def create!
    room = post('/rooms', id:    @channel[:id],
                          name:  @channel[:name],
                          user:  @user)
    if room['error'].present?
      @error = room['error']
    else
      @url = room['url']
    end
  end

  def post(path, params = {})
    uri = URI.parse("#{APP_CONFIG['eyeson_api']}#{path}")

    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['API_KEY'] = APP_CONFIG['eyeson_key']
    req.body = params.to_json

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    JSON.parse(res.body)
  end
end
