require 'rails_helper'

RSpec.describe TeamsController, type: :routing do
  it 'routes to setup' do
    expect(get: '/slack/setup').to route_to(
      action:     'setup',
      controller: 'teams'
    )
  end

  it 'routes to create' do
    expect(get: '/slack/setup/complete').to route_to(
      action:     'create',
      controller: 'teams'
    )
  end
end
