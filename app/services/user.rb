class User

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
      return Eyeson.new.get("/users/#{@email}")
    end

    def create
      return Eyeson.new.post("/users", {
        name: @name,
        email: @email
      })
    end
  
end