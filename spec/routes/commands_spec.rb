require 'rails_helper'

RSpec.describe CommandsController, type: :routing do
  it 'routes to create' do
    expect(post: '/slack/commands').to route_to(
      action:     'create',
      controller: 'commands'
    )
  end
end
