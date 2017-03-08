# Adds files to Slack
module SlackFile

  def upload_file!(body)
    request('/files.upload',
            channel:   channel.external_id,
            text:      'Test: Slide...',
            thread_ts: channel.thread_id)
  end

end
