# Generates individual API key for each team
class ApiKey
  attr_reader :key, :url, :error

  def initialize(name: nil, webhooks_url: nil)
    @name         = name
    @webhooks_url = webhooks_url
    @key          = nil
    @url          = nil
    @error        = nil
    @config       = Rails.configuration.services
    create!
  end

  private

  def create!
    team = post('/teams',
      name: @name,
      webhooks: {
        url: @webhooks_url,
        types: 'team_changed'
      }
    )
    if team['error'].present?
      @error = team['error']
    else
      @key = team['api_key']
      @url = team['links']['confirmation']
    end
  end

  def post(path, params = {})
    uri = URI.parse("#{@config['eyeson_api']}#{path}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req.body = params.to_json

    res = http.request(req)
    JSON.parse(res.body)
  end
end
