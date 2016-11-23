require 'rails_helper'

RSpec.describe CommandsController, type: :controller do
  it 'should raise an error with invalid token' do
    post :create, params: { token: 'blabla' }
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(
      I18n.t('.invalid_slack_token', scope: [:commands])
    )
  end

  it 'should raise an error with invalid team setup' do
    post :create, params: command_params.merge!(team_id: Faker::Code.isbn)
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(
      I18n.t('.invalid_setup',
             url: setup_url,
             scope: [:commands])
    )
  end

  it 'should redirect to setup properly' do
    get :setup
    expect(response).to redirect_to(
      login_path(redirect_uri: setup_complete_path)
    )
  end

  it 'should ask for command permissions on setup complete' do
    expects_authorize_with(
      redirect_uri: nil,
      scope:        'commands'
    )
    get :setup_complete
    expect(response.status).to redirect_to('https://slack/auth_url')
  end

  it 'should find team by team_id' do
    proper_setup
    post :create, params: command_params
    expect(Team.find_by(external_id: command_params[:team_id])).to be_present
  end

  it 'should save user to team' do
    proper_setup
    post :create, params: command_params
    team = Team.find_by(external_id: command_params[:team_id])
    user = team.users.where(external_id: command_params[:user_id])
    expect(user).to be_present
  end

  it 'should save channel to team' do
    proper_setup
    post :create, params: command_params
    team = Team.find_by(external_id: command_params[:team_id])
    channel = team.channels.where(external_id: command_params[:channel_id])
    expect(channel).to be_present
  end

  it 'should return a message' do
    proper_setup
    post :create, params: command_params
    url = "http://test.host/slack/m/#{command_params[:channel_id]}"
    text = I18n.t('.respond',
                  name: command_params[:user_name],
                  url: url,
                  scope: [:commands])
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(text)
  end
end

def proper_setup
  @team = create(:team)
end

def command_params
  {
    token: Rails.configuration.services['slack_token'],
    user_id:      '123',
    user_name:    'user_name',
    channel_id:   'abc',
    channel_name: 'channel_name',
    team_id:      @team.present? ? @team.external_id : Faker::Code.isbn
  }
end
