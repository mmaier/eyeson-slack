require 'rails_helper'

RSpec.describe CommandsController, type: :routing do
  it 'routes to setup' do
    expect(get: '/slack/setup').to route_to(
      action:     'setup',
      controller: 'commands'
    )
  end

  it 'routes to setup complete' do
    expect(get: '/slack/setup_complete').to route_to(
      action:     'setup_complete',
      controller: 'commands'
    )
  end

  it 'routes to create' do
    expect(post: '/slack/commands').to route_to(
      action:     'create',
      controller: 'commands'
    )
  end
end
