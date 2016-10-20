class Eyeson
  
  # Provides simplified CRUD methods to communicate with the eyeson API

  def initialize(user=nil)
    @user = user
  end

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
      if @user.present?
        @user.access_token
      else
        #TODO: use api key instead of admin user!
        credentials = {
          email: APP_CONFIG['eyeson_email'],
          password: APP_CONFIG['eyeson_pwd']
        }
        JSON.parse(Net::HTTP.post_form(URI.parse("#{APP_CONFIG['eyeson_api']}/auth"), credentials).body)["access_token"]
      end
    end
 
end