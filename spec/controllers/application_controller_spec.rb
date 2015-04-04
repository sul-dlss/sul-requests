require 'rails_helper'

describe ApplicationController do
  describe '#current_user' do
    it 'should return nil if there is no user in the environment' do
      expect(controller.send(:current_user)).to be_nil
    end
    it 'should return a user when there is a user in the environment' do
      allow(controller).to receive_messages(user_id: 'some-user')
      user = controller.send(:current_user)
      expect(user).to be_a User
      expect(user.webauth).to eq 'some-user'
    end
  end
end
