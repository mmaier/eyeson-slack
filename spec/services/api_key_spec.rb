require 'rails_helper'

RSpec.describe ApiKey, type: :class do
  it 'creates api key after initialization' do
    res = mock('Eyeson result', body: {
      api_key: '123'
    }.to_json)
    rest_response_with(res)

    api = ApiKey.new
    expect(api.key).to eq('123')
  end

  it 'raises errors' do
    res = mock('Eyeson result', body: { error: 'some_error' }.to_json)
    rest_response_with(res)
    expect { ApiKey.new }.to raise_error(ApiKey::ValidationFailed, 'some_error')
  end

  it 'uses basic auth for internal api' do
    @config = Rails.configuration.services
    res = mock('Eyeson result', body: {}.to_json)
    rest_response_with(res)
    auth = File.open(@config['internal_pwd'], &:readline)
    File.expects(:open)
        .with(@config['internal_pwd'])
        .returns(auth)
    req = mock('REST Request')
    req.expects(:basic_auth).with(auth.split(':').first, auth.split(':').last)
    req.expects(:[]=).once
    req.expects(:body=).once
    Net::HTTP::Post.expects(:new).returns(req)
    ApiKey.new
  end
end
