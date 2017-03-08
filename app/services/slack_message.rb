# Slack messaging
module SlackMessage
  def post_message!(channel: nil, thread_ts: nil, text: nil)
    post(
      '/chat.postMessage',
      channel:     channel,
      thread_ts:   thread_ts,
      text:        text
    )
  end
end
