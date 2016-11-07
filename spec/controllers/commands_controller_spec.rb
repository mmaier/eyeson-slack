require 'rails_helper'

RSpec.describe CommandsController, type: :controller do
  it 'should raise an error with invalid token' do
    post :respond, params: { token: 'blabla' }
    expect(JSON.parse(response.body)['text']).to eq('Verification not correct')
  end

  it 'should return a message' do
    user_id = '123'
    channel_id = 'xyz'
    post :respond, params: {
      token: APP_CONFIG['slack_token'],
      user_id: user_id,
      channel_id: channel_id
    }
    text = "#{user_id} created a videomeeting: http://test.host/m/#{channel_id}"
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(text)
  end
end
