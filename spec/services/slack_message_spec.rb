require 'rails_helper'

RSpec.describe SlackMessage, type: :class do
  let(:slack_api) do
    SlackApi.new
  end

  it 'should post a message' do
  	channel = create(:channel)
    slack_api.expects(:post).with('/chat.postMessage',
                                  channel:     channel.external_id,
														      thread_ts:   channel.thread_id,
														      text:        'hello',
                                  attachments: [{ test: true }].to_json)
    slack_api.post_message!(channel: channel.external_id, thread_ts: channel.thread_id, text: 'hello', attachments: [{ test: true }])
  end
end
