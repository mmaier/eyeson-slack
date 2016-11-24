require 'rails_helper'

RSpec.describe Room, type: :class do
  let(:room) do
    Room.new(
      channel: create(:channel),
      user:    create(:user)
    )
  end

  it 'gets and sets url after initialization' do
    res = mock('Eyeson result', body: { links: { gui: 'gui_url' } }.to_json)
    rest_response_with(res)

    expect(room.url).to eq('gui_url')
  end

  it 'raises errors' do
    res = mock('Eyeson result', body: { error: 'some_error' }.to_json)
    rest_response_with(res)

    expect{room}.to raise_error(Room::ValidationFailed, 'some_error')
  end
end
