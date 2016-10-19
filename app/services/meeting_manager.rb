class MeetingManager

  def initialize(user, channel)
    @user = user
    @channel = channel
  end

  def create!
    return "#{@user[:name]} created a meeting for #{@channel[:name]}"
  end
end