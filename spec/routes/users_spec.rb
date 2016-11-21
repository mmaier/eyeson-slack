require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  it 'routes to setup' do
    expect(get: '/slack/setup').to route_to(
      action:     'setup',
      controller: 'users'
    )
  end

  it 'routes to setup_webhook' do
    expect(post: '/slack/setup').to route_to(
      action:     'setup_webhook',
      controller: 'users'
    )
  end

  it 'routes to login' do
    expect(get: '/slack/login').to route_to(
      action:     'login',
      controller: 'users'
    )
  end

  it 'routes to oauth response' do
    expect(get: '/slack/oauth').to route_to(
      action:     'oauth',
      controller: 'users'
    )
  end
end
