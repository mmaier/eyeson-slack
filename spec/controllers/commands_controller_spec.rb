require 'rails_helper'

RSpec.describe CommandsController, type: :controller do
  let(:team) { create(:team) }
  let(:channel) { create(:channel, team: team) }
  let(:user) { create(:user, team: team) }

  it 'should raise an error with invalid token' do
    post :create, params: { token: 'blabla' }
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(
      I18n.t('.invalid_slack_token', scope: [:commands])
    )
  end

  it 'should raise an error with invalid team setup' do
    post :create, params: command_params.merge(team_id: Faker::Code.isbn)
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(
      I18n.t('.invalid_setup',
             url: setup_url,
             scope: [:commands])
    )
  end

  it 'should find team by team_id' do
    post :create, params: command_params
    expect(Team.find_by(external_id: command_params[:team_id])).to be_present
  end

  it 'should setup channel info for meetings' do
    channel
    Channel.expects(:find_or_initialize_by).with(
      team: team,
      external_id: command_params[:channel_id]
    ).returns(channel)
    channel.expects(:name=).with(command_params[:channel_name])
    channel.expects(:initializer_id=).with(user.id)
    channel.expects(:thread_id=).with(nil)
    channel.expects(:webinar_mode=).with(false)
    channel.expects(:save!)
    post :create, params: command_params
  end

  it 'should setup channel info for webinars' do
    channel
    Channel.expects(:find_or_initialize_by).with(
      team: team,
      external_id: command_params[:channel_id] + '_webinar'
    ).returns(channel)
    channel.expects(:name=).with(command_params[:channel_name])
    channel.expects(:initializer_id=).with(user.id)
    channel.expects(:thread_id=).with(nil)
    channel.expects(:webinar_mode=).with(true)
    channel.expects(:save!)
    post :create, params: command_params.merge(command: '/eyeson-test-webinar')
  end

  it 'should skip team and channel for help' do
    Team.expects(:find_by).never
    Channel.expects(:find_or_initialize_by).never
    post :create, params: command_params.merge(text: 'help')
  end

  it 'should save channel to team' do
    post :create, params: command_params
    team = Team.find_by(external_id: command_params[:team_id])
    channel = team.channels.where(external_id: command_params[:channel_id])
    expect(channel).to be_present
  end

  it 'should return a meeting link' do
    post :create, params: command_params
    url = "http://test.host/slack/m/#{command_params[:channel_id]}"
    text = I18n.t('.meeting_response',
                  url: url,
                  scope: [:commands])
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(text)
  end

  it 'should return a webinar link' do
    post :create, params: command_params.merge(command: '/eyeson-test-webinar')
    url = "http://test.host/slack/w/#{command_params[:channel_id]}_webinar"
    text = I18n.t('.webinar_response',
                  url: url,
                  users: nil,
                  scope: [:commands])
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(text)
  end

  it 'should provide a help response' do
    post :create, params: command_params.merge(text: 'help')
    text = I18n.t('.help',
                  url: Rails.configuration.services['faq_url'],
                  scope: [:commands])
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['text']).to eq(text)
  end
end

def command_params
  {
    token: Rails.application.secrets.slack_token,
    command:      '/eyeson-test',
    user_id:      user.external_id,
    user_name:    user.name,
    channel_id:   channel.external_id,
    channel_name: channel.name,
    team_id:      team.external_id,
    response_url: Faker::Internet.url
  }
end
