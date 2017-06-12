require 'rails_helper'

RSpec.describe MeetingsController, type: :routing do
  it 'routes to meeting' do
    expect(get: '/slack/m/123').to route_to(
      id: 				'123',
      action:     'show',
      controller: 'meetings'
    )
  end

  it 'routes to webinar' do
    expect(get: '/slack/w/123').to route_to(
      id: 				'123',
      action:     'show',
      controller: 'meetings',
      webinar:    true
    )
  end
end
