# Manages conf rooms
class Room
  include Eyeson

  attr_accessor :error
  attr_reader :url

  def initialize(channel: {}, user: {})
    @channel = channel
    @user    = user
    @url     = nil
    create!
  end

  private

  def create!
    room = post('/rooms', id:    @channel[:id],
                          name:  @channel[:name],
                          user:  @user)
    if room['error'].present?
      self.error = room['error']
    else
      @url = room['room']['url']
    end
  end
end
