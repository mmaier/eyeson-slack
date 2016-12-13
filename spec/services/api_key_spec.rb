require 'rails_helper'

RSpec.describe ApiKey, type: :class do
  it 'creates api key after initialization' do
    res = mock('Eyeson result', body: {
      api_key: '123'
    }.to_json)
    uses_internal_api
    api_response_with(res)

    api = ApiKey.new(Faker::Internet.email)
    expect(api.key).to eq('123')
  end

  it 'raises errors' do
    res = mock('Eyeson result', body: { error: 'some_error' }.to_json)
    uses_internal_api
    api_response_with(res)
    expect { ApiKey.new(Faker::Internet.email) }
      .to raise_error(ApiKey::ValidationFailed, 'some_error')
  end

  it 'uses basic auth for internal api' do
    res = mock('Eyeson result', body: {}.to_json)
    uses_internal_api
    api_response_with(res)
    ApiKey.new(Faker::Internet.email)
  end
end
