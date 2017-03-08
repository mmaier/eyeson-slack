require 'rails_helper'

RSpec.describe SlackFile, type: :class do
  let(:slack_api) do
    SlackApi.new
  end

  it 'should upload a file' do
    slack_api.expects(:request).with('/files.upload',
                                    content: 'content',
                                    filename: 'name')
    slack_api.upload_file!(content: 'content', filename: 'name')
  end
end
