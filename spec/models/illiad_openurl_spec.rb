require 'rails_helper'

describe IlliadOpenurl do
  let(:lib_user) { create(:webauth_user).tap { |x| x.ldap_group_string = 'organization:sul' } }
  let(:law_user) { create(:webauth_user).tap { |x| x.ldap_group_string = 'organization:law' } }
  let(:gsb_user) { create(:webauth_user).tap { |x| x.ldap_group_string = 'organization:gsb' } }

  let(:scan) { create(:scan_with_holdings_barcode) }
  let(:redirect_url) { '' }

  subject { IlliadOpenurl.new(user, scan, redirect_url) }

  describe '#to_url' do
    let(:user) { lib_user }

    context 'for a law user' do
      let(:user) { law_user }

      it 'uses the appropriate illiad instance' do
        expect(subject.to_url).to include '/rcj/illiad'
      end
    end

    context 'for a gsb user' do
      let(:user) { gsb_user }

      it 'uses the appropriate illiad instance' do
        expect(subject.to_url).to include '/s7z/illiad'
      end
    end

    it 'uses the st2 illiad instance' do
      expect(subject.to_url).to include '/st2/illiad'
    end
  end
end
