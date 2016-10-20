class Meeting

  # Manages meetings referring to eyeson dependencies

	attr_accessor :url, :error

  def initialize(user, channel)
    @user = user
    @channel = channel
    
    create
  end

  private

  	def create
  		meeting = Eyeson.new.post("/users/#{@user.id}/meetings", {
        title: @channel[:name],
        from: Time.now.utc.iso8601,
        to: 30.minutes.from_now.utc.iso8601
      })
      if meeting["error"].present?
      	self.error = meeting["error"]
      else
      	self.url = meeting["webinar"]["url"]
      end
  	end
  
end