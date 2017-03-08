# Adds files to Slack
module SlackFile
  def upload_file!(file: nil, filename: nil)
    post(
      '/files.upload',
      file: file,
      filename: filename
    )
  end
end
