# Generates individual API key for each team
class ApiKey
  class ValidationFailed < StandardError
  end

  attr_reader :key

  def initialize(name: nil, email: nil)
    @name   = name
    @email  = email
    @key    = nil
    @config = Rails.configuration.services
    create!
  end

  private

  def create!
    team = post('/internal/teams',
                email: @email,
                name:  @name)
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

    auth = YAML.load(File.read(@config['internal_pwd']))
    req.basic_auth auth['username'], auth['password']
    req['Content-Type'] = 'application/json'

    res = http.request(req)
    JSON.parse(res.body)
  end
end
