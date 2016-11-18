require 'rails_helper'

RSpec.describe Room, type: :class do
  it 'gets and sets url after initialization' do
    res = mock('Eyeson result', body: { links: { gui: 'gui_url' } }.to_json)
    rest_response_with(res)

    room = Room.new(
      channel: create(:channel),
      user:    create(:user)
    )

    expect(room.url).to eq('gui_url')
    expect(room.error).to be_nil
  end

  it 'handle errors' do
    res = mock('Eyeson result', body: { error: 'some_error' }.to_json)
    rest_response_with(res)

    room = Room.new(
      channel: create(:channel),
      user:    create(:user)
    )

    expect(room.url).to be_nil
    expect(room.error).to eq('some_error')
  end
end
