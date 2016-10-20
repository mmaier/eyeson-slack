class Meeting

  # Manages meetings referring to eyeson dependencies

	attr_accessor :error

  def initialize(id=nil)
    @id = id
    @user_id = nil
    find if @id.present?
  end

  def create(user, channel)
    meeting = Eyeson.new(user).post("/meetings", {
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

  def add(user_id)
    user = User.new(id: @user_id)
    Eyeson.new(user).post("/meetings/#{@id}/participations", {
      user_id: user_id
    })
    return "#{self.url}?access_token=#{user.access_token}"
  end

  def url
    APP_CONFIG['eyeson_api'].split("/api/v2").first+'/'+@id
  end

  private

    def find
      meeting = Eyeson.new.get("/meetings/#{@id}")
      if meeting["error"].present?
        self.error = meeting["error"]
        return false
      else
        @user_id = meeting["webinar"]["user_id"]
        self.error = nil
        return true
      end
    end
  
end