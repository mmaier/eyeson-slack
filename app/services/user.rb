class User

	attr_reader :name

	def initialize(id: nil, name: nil)
    @id = id
    @name = name
  end
  
end