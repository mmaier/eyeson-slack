require 'rails_helper'

RSpec.describe Room, type: :class do
  let(:user) do
    create(:user)
  end
  let(:room) do
    Room.new(
      channel: create(:channel),
      user:    user
    )
  end

  it 'gets and sets url after initialization' do
    res = mock('Eyeson result', body: { links: { gui: 'gui_url' } }.to_json)
    api_response_with(res)

    expect(room.url).to eq('gui_url')
  end

  it 'raises errors' do
    res = mock('Eyeson result', body: { error: 'some_error' }.to_json)
    api_response_with(res)

    expect { room }.to raise_error(Room::ValidationFailed, 'some_error')
  end

  it 'should contain correct user fields in mapped_user' do
    res = mock('Eyeson result', body: { links: { gui: 'gui_url' } }.to_json)
    api_response_with(res)
    user.ip_address = Faker::Internet.ip_v4_address
    mapped = room.send(:mapped_user)
    expect(mapped[:id]).to eq(user.email)
    expect(mapped[:name]).to eq(user.name)
    expect(mapped[:avatar]).to eq(user.avatar)
    expect(mapped[:ip_address]).to eq(user.ip_address)
  end
end
