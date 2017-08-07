require 'rails_helper'

RSpec.describe RecordingsController, type: :controller do
  it 'should redirect_to download url' do
    url = Faker::Internet.url
    Eyeson::Recording.expects(:find).with('123').returns(mock('Recording', url: url))
    get :show, params: { id: '123' }
    expect(response).to redirect_to(url)
  end
end
