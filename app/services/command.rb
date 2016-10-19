class Command

	attr_accessor :payload, :status

	def initialize(command)
    @command = begin
    	command.split("/")[1]
    rescue
    	""
    end
  end

  def execute(params)
  	self.class.private_method_defined?(@command) ? self.send(@command, params) : error
    return self
  end

  private

  	def eyeson(user: nil, params: nil)
			channel = {
				id: params[:channel_id],
				name: params[:channel_name]
			}
			meeting = Meeting.new(user, channel)
			self.payload = {
		    response_type: :in_channel,
		    text: (meeting.error.present? ? meeting.error : "#{user.name} created a videomeeting: #{meeting.url}")
			}
			self.status = :ok
  	end

  	def error
  		self.payload = {error: "Command not known"}
  		self.status = :method_not_allowed
  	end
  
end