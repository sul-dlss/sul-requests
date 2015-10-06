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
      allow(controller).to receive_messages(ldap_attributes: { 'WEBAUTH_LDAPPRIVGROUP' => 'ldap:group1|ldap:group2' })
      user = controller.send(:current_user)
      expect(user.ldap_groups).to eq ['ldap:group1', 'ldap:group2']
    end
    it 'has the SUCARD Number id from LDAP and translates it to the library_id' do
      allow(controller).to receive_messages(user_id: 'some-user')
      allow(controller.request).to receive(:env).and_return('WEBAUTH_LDAP_SUCARDNUMBER' => '12345987654321')
      user = controller.send(:current_user)
      expect(user).to be_a User
      expect(user.library_id).to eq '987654321'
      expect(user).not_to be_changed
    end
  end

  describe '#ldap_attributes' do
    it 'uses the request env' do
      allow(controller.request).to receive(:env).and_return('a' => 1)
      expect(controller.send(:ldap_attributes)).to include 'a' => 1
    end

    it 'enriches the request env with local settings' do
      allow(controller).to receive_messages(user_id: 'some-user')
      allow(controller.request).to receive(:env).and_return('a' => 1)
      allow(Rails.env).to receive(:development?).and_return(true)
      Settings.fake_ldap_attributes ||= {}
      allow(Settings).to receive(:fake_ldap_attributes).and_return('some-user' => { 'b' => 2 })
      expect(controller.send(:ldap_attributes)).to include 'a' => 1, 'b' => 2
    end
  end
end
