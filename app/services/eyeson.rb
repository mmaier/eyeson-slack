class Eyeson

  def get(path, params={})
    uri = URI.parse("#{APP_CONFIG['eyeson_api']}#{path}")
    params.merge!({access_token: access_token})
    uri.query = URI.encode_www_form(params)
    return JSON.parse(Net::HTTP.get_response(uri).body)
  end

  def post(path, params={})
    uri = URI.parse("#{APP_CONFIG['eyeson_api']}#{path}")
    params.merge!({access_token: access_token})
    return JSON.parse(Net::HTTP.post_form(uri, params).body)
  end

  private

  def access_token
    #TODO: use api key instead of admin user!
    return JSON.parse(Net::HTTP.post_form(URI.parse("#{APP_CONFIG['eyeson_api']}/auth"), {
     email: APP_CONFIG['eyeson_email'],
     password: APP_CONFIG['eyeson_pwd']
    }).body)["access_token"]
  end
 
end