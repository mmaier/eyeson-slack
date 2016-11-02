# Provides simplified CRUD methods to communicate with the eyeson API
module Eyeson

  included do
    def get(path, params={})
      uri = URI.parse("#{APP_CONFIG['eyeson_api']}#{path}")
      #Add API_KEY header: APP_CONFIG['eyeson_key']
      uri.query = URI.encode_www_form(params)
      return JSON.parse(Net::HTTP.get_response(uri).body)
    end

    def post(path, params={})
      uri = URI.parse("#{APP_CONFIG['eyeson_api']}#{path}")
      #Add API_KEY header: APP_CONFIG['eyeson_key']
      return JSON.parse(Net::HTTP.post_form(uri, params).body)
    end
  end

end