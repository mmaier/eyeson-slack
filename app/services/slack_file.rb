# Adds files to Slack
module SlackFile
  def upload_file!(content: nil, filename: nil)
    post(
      '/files.upload',
      content:  content,
      filename: filename
    )
  end
end
