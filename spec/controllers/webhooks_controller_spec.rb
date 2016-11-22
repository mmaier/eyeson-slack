require 'rails_helper'

RSpec.describe WebhooksController, type: :controller do
  it 'raises an error on invalid type' do
    params = {
      type: 'blabla'
    }
    post :create, params: params
    expect(
      JSON.parse(response.body)['error']
    ).to eq(I18n.t('.invalid_type', scope: [:webhooks]))
  end

  it 'raises an error on invalid team' do
    params = {
      type: 'team_changed',
      api_key: Faker::Crypto.md5
    }
    post :create, params: params
    expect(
      JSON.parse(response.body)['error']
    ).to eq(I18n.t('.team_not_found', scope: [:webhooks]))
  end

  it 'can handle webhook for team_changed' do
    team = create(:team, ready: false)
    params = {
      type: 'team_changed',
      api_key: team.api_key,
      team: { ready: true }
    }
    post :create, params: params
    team.reload
    expect(team.ready).to eq(true)
  end
end
