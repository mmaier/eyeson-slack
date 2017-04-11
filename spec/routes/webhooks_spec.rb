require 'rails_helper'

RSpec.describe WebhooksController, type: :routing do
  it 'routes to create' do
    expect(post: '/hipchat/webhooks').to route_to(
      action:     'create',
      controller: 'webhooks'
    )
  end
end
