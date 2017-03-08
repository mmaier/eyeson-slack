# Adds files to Slack
module SlackFile
  def upload_file!(file: nil, filename: nil)
    req = RestClient::Request.new(
      method: :post,
      url: 'https://slack.com/api/files.upload',
      payload: {
      	file: file,
      	filename: filename
      }
    )
    respond_with(req.execute)
  end
end
