class CommandJob < ApplicationJob
  queue_as :default

  def perform(params)
    command = begin
    	params[:command].split("/")[1]
    rescue
    	""
    end
    self.class.private_method_defined?(command) ? self.send(command, params) : error(params)
  end

  private

  	def eyeson(params)
			channel = {
				id: params[:channel_id],
				name: params[:channel_name]
			}
      user = User.new(id: params[:user_id], name: params[:user_name])
			meeting = Meeting.new(user, channel)

			payload = {
		    response_type: :in_channel,
		    text: (meeting.error.present? ? meeting.error : "#{user.name} created a videomeeting: #{meeting.url}")
			}
			respond!(params[:response_url], payload)
  	end

  	def error(params)
  		payload = {
		    response_type: :in_channel,
		    text: "Command not known"
			}
  		respond!(params[:response_url], payload)
  	end

  	def respond!(url, payload)
      request = Net::HTTP::Post.new(url, 'Content-Type' => 'application/json')
      request.body = payload.to_json
      resp = http.request(request)
  	end
end
