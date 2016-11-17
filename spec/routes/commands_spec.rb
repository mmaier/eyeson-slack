require 'rails_helper'

RSpec.describe CommandsController, type: :routing do
  it 'routes for commands' do
    expect(post: '/slack/commands').to route_to(
      action:     'respond',
      controller: 'commands',
      format:     :json
    )
  end
end
