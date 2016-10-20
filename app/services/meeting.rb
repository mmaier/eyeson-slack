class Meeting

  # Manages meetings referring to eyeson dependencies

	attr_accessor :id, :error

  def initialize(id=nil)
    @id = id
  end

  def create(user, channel)
    meeting = Eyeson.new.post("/users/#{user.id}/meetings", {
      title: channel[:name],
      from: Time.now.utc.iso8601,
      to: 30.minutes.from_now.utc.iso8601
    })
    if meeting["error"].present?
      self.error = meeting["error"]
    else
      self.id = meeting["webinar"]["id"]
    end
  end

  def add(user_id)
    Eyeson.new.post("/meetings/#{self.id}/participations", {
      user_id: user_id
    })
  end

  def url
    APP_CONFIG['eyeson_api'].split("/api/v2").first+'/'+self.id
  end
  
end