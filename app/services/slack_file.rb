# Adds files to Slack
module SlackFile
  def upload_file!(content: nil, filename: nil)
    request(
      '/files.upload',
      content:  content,
      filename: filename
    )
  end
end
