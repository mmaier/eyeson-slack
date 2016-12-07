# Generates individual API key for each team
class ApiKey
  class ValidationFailed < StandardError
  end

  attr_reader :key, :url

  def initialize
    @key    = nil
    @url    = nil
    @config = Rails.configuration.services
    @auth   = File.open(@config['internal_pwd'], &:readline)
    create!
  end

  private

  def create!
    team = post('/internal/teams',
                name: 'Slack Service Application')
    raise ValidationFailed, team['error'] if team['error'].present?
    @key = team['api_key']
  end

  def post(path, params = {})
    uri = URI.parse("#{@config['eyeson_api']}#{path}")
    req = Net::HTTP::Post.new(uri)
    req.body = params.to_json
    request(uri, req)
  end

  def request(uri, req)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req.basic_auth @auth.split(':').first, @auth.split(':').last
    req['Content-Type'] = 'application/json'

    res = http.request(req)
    JSON.parse(res.body)
  end
end
