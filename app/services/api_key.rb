# Generates individual API key for each team
class ApiKey
  class ValidationFailed < StandardError
  end

  attr_reader :key, :url

  def initialize
    @key          = nil
    @url          = nil
    @config       = Rails.configuration.services
    create!
  end

  private

  def create!
    team = post('/teams',
                name: 'Slack Service Application')
    raise ValidationFailed, team['error'] if team['error'].present?
    @key = team['api_key']
    @url = team['links']['setup']
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
