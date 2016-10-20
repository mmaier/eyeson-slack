class CommandJob < ApplicationJob
  queue_as :default

  def perform(params)
    # Command param comes with prepended '/' char, so we need to extract the command
    command = begin params[:command].split("/")[1] rescue "" end
      
    # Check if command is available, otherwise raise an error
    self.class.private_method_defined?(command) ? self.send(command, params) : error(params)
  end

  private

  	def eyeson(params)
      # Create a videomeeting based on the channel id
			channel = {
				id: params[:channel_id],
				name: params[:channel_name]
			}
      user = User.new(id: params[:user_id], name: params[:user_name])
			meeting = Meeting.new(user, channel)

      # Meeting link will be posted to all users in channel
      if meeting.error.nil?
        payload = {
          response_type: :in_channel,
          color: :good,
          text: "#{user.name} created a videomeeting: #{meeting_url(id: meeting.id)}"
        }
      else
        payload = {
          color: :danger,
          pretext: "There was a problem with your command:",
          text: meeting.error
        }
      end
			respond!(params[:response_url], payload)
  	end

  	def error(params)
  		payload = {
		    response_type: :in_channel,
        color: :danger,
		    text: "Sorry, I don't know what to do with your command"
			}
  		respond!(params[:response_url], payload)
  	end

  	def respond!(url, payload)
      uri = URI(url)
      https = Net::HTTP.new(uri.host,uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
      req.body = payload.to_json
      res = https.request(req)
  	end
end
