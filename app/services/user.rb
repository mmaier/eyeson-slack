class User

  # A simple user manager for finding/creating user models in eyeson

  attr_accessor :error
	attr_reader :id, :name

	def initialize(id: nil, name: nil)
    @id = id
    @name = name

    #TODO: use external_id for API requests instead of fake emails!
    @email = "#{@id}@slack.eyeson.solutions"

    find || create
  end

  private

    def find
      user = Eyeson.new.get("/users/#{@email}")
      if user["error"].present?
        self.error = user["error"]
        return false
      else
        self.error = nil
        return true
      end
    end

    def create
      user = Eyeson.new.post("/users", {
        name: @name,
        email: @email
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