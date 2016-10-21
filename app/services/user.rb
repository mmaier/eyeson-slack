class User < Eyeson

  # A simple user manager for finding/creating user models in eyeson

  attr_accessor :error
  attr_reader :name

	def initialize(id: nil, name: nil)
    @id = id
    @name = name

    #TODO: use id for API requests instead of fake emails!
    @email = "#{@id}@slack.eyeson.solutions"

    find || create
  end

  def access_token
    #TODO: get valid access_token from eyeson API and use that for the web session
    credentials = {
      email: @email,
      password: password
    }
    JSON.parse(Net::HTTP.post_form(URI.parse("#{APP_CONFIG['eyeson_api']}/auth"), credentials).body)["access_token"]
  end

  private

    def password
      #TODO: remove once access_token can be optained the easy way
      Digest::MD5.hexdigest(@email)
    end

    def find
      user = get("/users/#{@email}")
      if user["error"].present?
        self.error = user["error"]
        return false
      else
        self.error = nil
        return true
      end
    end

    def create
      user = post("/users", {
        name: @name,
        email: @email,
        password: password
      })
      if user["error"].present?
        self.error = user["error"]
        return false
      else
        self.error = nil
        return true
      end
    end
  
end