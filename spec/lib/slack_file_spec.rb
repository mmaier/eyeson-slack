require 'rails_helper'

RSpec.describe SlackFile, type: :class do
  let(:slack_api) do
    SlackApi.new
  end

  it 'should upload a file' do
  	file = Tempfile.new('file')
    slack_api.expects(:multipart).with('/files.upload',
                                  file: file,
                                  filename: 'name')
    slack_api.upload_file!(file: file, filename: 'name')
  end
end
