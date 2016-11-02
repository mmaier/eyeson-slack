# Manages conf rooms
class Room
  include Eyeson

  attr_accessor :error
  attr_reader :url

  def initialize(channel = {})
    @channel = channel
    @url     = nil
    create!
  end

  private

  def create!
    room = post('/rooms', id:        @channel[:id],
                          name:      @channel[:name])
    if room['error'].present?
      self.error = room['error']
    else
      @url = room['room']['url']
    end
  end
end
