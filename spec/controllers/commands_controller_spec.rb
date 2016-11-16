require 'rails_helper'

RSpec.describe CommandsController, type: :controller do
  it 'should raise an error with invalid token' do
    post :respond, params: { token: 'blabla' }
    expect(JSON.parse(response.body)['text']).to eq('Verification not correct')
  end

  it 'should return a message' do
    user = 'user.name'
    channel_id = 'xyz'
    post :respond, params: {
      token: Rails.configuration.services['slack_token'],
      user_id: '123',
      user_name: user,
      channel_id: channel_id
    }
    url = "http://test.host/slack/m/#{channel_id}"
    text = "#{user} created a videomeeting: #{url}"
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(text)
  end
end
