require 'rails_helper'

describe ApplicationController do
  describe '#current_user' do
    it 'should return nil user if there is no user in the environment' do
      user = controller.send(:current_user)
      expect(user).to be_a User
      expect(user).to_not be_persisted
      expect(user.id).to be_nil
    end
    it 'should return a user when there is a user in the environment' do
      allow(controller).to receive_messages(user_id: 'some-user')
      user = controller.send(:current_user)
      expect(user).to be_a User
      expect(user.webauth).to eq 'some-user'
    end
    it 'should return the ldap groups as an array' do
      allow(controller).to receive_messages(user_id: 'some-user')
      allow(controller).to receive_messages(request_ldap: 'ldap:group1|ldap:group2')
      user = controller.send(:current_user)
      expect(user.ldap_groups).to eq ['ldap:group1', 'ldap:group2']
    end
  end
end
