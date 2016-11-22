require 'rails_helper'

RSpec.describe UsersController, type: :routing do
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
