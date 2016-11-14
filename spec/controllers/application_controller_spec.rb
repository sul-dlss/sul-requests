require 'rails_helper'

describe ApplicationController do
  it '#current_user calls CurrentUser.for(request)' do
    expect(CurrentUser).to receive(:for)
    controller.send(:current_user)
  end
end
