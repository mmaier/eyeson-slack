require 'rails_helper'

RSpec.describe Intercom, type: :module do
  include Intercom

  it 'should execute requests in new thread' do
    user = build(:user)
    Thread.expects(:new)
    Intercom::User.new(user)
  end

  it 'should provide a request method' do
    req = mock('Intercom Request')
    req.expects(:use_ssl=).with(true)
    req.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
    req.expects(:request).returns(true)
    Net::HTTP.expects(:new).returns(req)
    uri = URI.parse('https://test.host/intercom')
    Intercom.request(Net::HTTP::Post.new(uri), uri, {})
  end

  it 'should return custom attributes for new user' do
    user = build(:user)
    Thread.expects(:new)
    intercom = Intercom::User.new(user)
    intercom.instance_variable_set(:@existing_user, {})
    custom_attributes = {
      first_login_source: 'Meeting Room',
      last_login_source: 'Meeting Room',
      first_meeting_date: user.created_at.to_i,
      first_meeting_info: "Slack #{user.team.name}",
      last_meeting_info: "Slack #{user.team.name}",
      count_slack: 1
    }
    expect(intercom.send(:custom_attributes)).to eq(custom_attributes)
  end

  it 'should return custom attributes for existing user' do
    user = build(:user)
    Thread.expects(:new)
    intercom = Intercom::User.new(user)
    intercom.instance_variable_set(:@existing_user, {:custom_attributes => {:count_slack => 1}})
    custom_attributes = {
      last_login_source: 'Meeting Room',
      last_meeting_info: "Slack #{user.team.name}",
      count_slack: 2
    }
    expect(intercom.send(:custom_attributes)).to eq(custom_attributes)
  end

  it 'should return user info' do
    user = build(:user)
    Thread.expects(:new)
    intercom = Intercom::User.new(user, ip_address: '127.0.0.1')
    user_item = {
      email: user.email,
      name: user.name,
      new_session: true,
      update_last_request_at: true,
      last_seen_ip: '127.0.0.1',
      custom_attributes: intercom.send(:custom_attributes)
    }
    expect(intercom.send(:user_item)).to eq(user_item)
  end

  it 'should return existing user' do
    user = build(:user, external_id: Faker::Internet.email)
    Thread.expects(:new)
    intercom = Intercom::User.new(user)
    Intercom.expects(:get)
    intercom.send(:fetch_user!)
  end
end
