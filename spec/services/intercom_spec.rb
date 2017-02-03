require 'rails_helper'

RSpec.describe Intercom, type: :module do
  include Intercom

  it 'should execute requests in new thread' do
    user = create(:user)
    Thread.expects(:new)
    Intercom::User.new(user)
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
    user = build(:user)
    Thread.expects(:new)
    intercom = Intercom::User.new(user, ip_address: '127.0.0.1')
    user_item = {
      email: user.email,
      last_seen_ip: '127.0.0.1'
    }
    expect(intercom.send(:user_item)).to eq(user_item)
  end
end
