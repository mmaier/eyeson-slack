class Meeting < Eyeson

  # Manages meetings referring to eyeson dependencies

	attr_accessor :error
  attr_reader :id

  def initialize(id=nil)
    @id = id
    find if @id.present?
  end

  def create(user, channel)
    @access_token = user.access_token
    meeting = post("/meetings", {
      title: channel[:name],
      from: Time.now.utc.iso8601,
      to: 30.minutes.from_now.utc.iso8601
    })
    if meeting["error"].present?
      self.error = meeting["error"]
    else
      @id = meeting["webinar"]["id"]
    end
    return self
  end

  private

    def find
      meeting = get("/meetings/#{@id}")
      if meeting["error"].present?
        self.error = meeting["error"]
        return false
      else
        self.error = nil
        return true
      end
    end
  
end