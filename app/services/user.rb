class User

  # A simple user manager for finding/creating user models in eyeson

  attr_accessor :error, :access_token
	attr_reader :id, :external_id, :name, :email

	def initialize(id: nil, external_id: nil, name: nil)
    @id = id
    @external_id = external_id
    @name = name

    #TODO: use external_id for API requests instead of fake emails!
    @email = "#{@external_id}@slack.eyeson.solutions"

    find || create

    #TODO: get valid access_token from eyeson API and use that for the web session
    credentials = {
      email: self.email,
      password: self.password
    }
    self.access_token = JSON.parse(Net::HTTP.post_form(URI.parse("#{APP_CONFIG['eyeson_api']}/auth"), credentials).body)["access_token"]
  end

  def password
    #TODO: get valid access_token from eyeson API and use that for the web session
    Digest::MD5.hexdigest(self.email)
  end

  private

    def find
      user = Eyeson.new.get("/users/#{@email}")
      if user["error"].present?
        self.error = user["error"]
        return false
      else
        @id = user["user"]["id"]
        self.error = nil
        return true
      end
    end

    def create
      user = Eyeson.new.post("/users", {
        name: @name,
        email: @email,
        password: self.password
      })
      if user["error"].present?
        self.error = user["error"]
        return false
      else
        @id = user["user"]["id"]
        self.error = nil
        return true
      end
    end
  
end