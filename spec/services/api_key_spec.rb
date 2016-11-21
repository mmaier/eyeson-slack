require 'rails_helper'

RSpec.describe ApiKey, type: :class do
  it 'creates api key after initialization' do
    res = mock('Eyeson result', body: {
      api_key: '123',
      links: {
        confirmation: 'confirm_url'
      }
    }.to_json)
    rest_response_with(res)

    api = ApiKey.new(
      name: 'my app'
    )

    expect(api.key).to eq('123')
    expect(api.url).to eq('confirm_url')
    expect(api.error).to be_nil
  end

  it 'creates api key after initialization' do
    res = mock('Eyeson result', body: { error: 'some_error' }.to_json)
    rest_response_with(res)

    api = ApiKey.new(
      name: 'my app'
    )

    expect(api.key).to be_nil
    expect(api.url).to be_nil
    expect(api.error).to eq('some_error')
  end
end
