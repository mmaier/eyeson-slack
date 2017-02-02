require 'rails_helper'

RSpec.describe Intercom, type: :module do
  include Intercom

  it 'should provide a User class' do
    Net::HTTP.expects(:new).never
    intercom = Intercom::User.new(nil)
    expect(intercom).to be_present
  end

  it 'should not execute outside of production env' do
    Rails.env.expects(:production?).returns(false)
    Intercom.expects(:request).never
    Intercom::User.new(nil)
  end

  it 'should provide a request method' do
    req = mock('Intercom Request')
    req.expects(:use_ssl=).with(true)
    req.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
    req.expects(:request).returns(true)
    Net::HTTP.expects(:new).returns(req)
    Intercom.request(URI.parse('https://test.host/intercom'), {})
  end

  it 'should return ip and email for user update' do
    Rails.env.expects(:production?).returns(true)
    user = build(:user)
    Intercom.expects(:request)
    intercom = Intercom::User.new(user, ip_address: '127.0.0.1')
    user_item = {
      email: user.email,
      last_seen_ip: '127.0.0.1'
    }
    expect(intercom.send(:user_item)).to eq(user_item)
  end

  it 'should invoke intercom api with user info' do
    user = create(:user)
    uri = URI.parse('https://api.intercom.io/bulk/users')
    Rails.env.expects(:production?).returns(true)
    Intercom.expects(:request)
    Intercom::User.new(user, ip_address: nil)
  end
end
