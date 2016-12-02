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

  # it uses webbhooks url on setup

  it 'raises errors' do
    res = mock('Eyeson result', body: { error: 'some_error' }.to_json)
    rest_response_with(res)
    expect { ApiKey.new }.to raise_error(ApiKey::ValidationFailed, 'some_error')
  end
end
