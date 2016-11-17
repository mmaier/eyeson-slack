require 'rails_helper'

RSpec.describe MeetingsController, type: :routing do
  it 'routes to join' do
    expect(get: '/slack/m/123').to route_to(
      id: 				'123',
      action:     'show',
      controller: 'meetings'
    )
  end
end
