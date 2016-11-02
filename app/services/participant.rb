# Add users to conf rooms
class Participant
  include Eyeson

	attr_accessor :error
  attr_reader :url

  def initialize(channel_id = nil, user = {})
    @channel_id = channel_id
    @user       = user
    @url        = nil
    create!
  end

  private

  def create!
    participant = post("/rooms/#{@channel_id}/participants", {
      id:   @user[:id],
      name: @user[:name]
    })
    if participant["error"].present?
      self.error = participant["error"]
    else
      @url = participant["room"]["url"]
    end
  end
  
end