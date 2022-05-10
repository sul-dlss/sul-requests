# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Patron do
  subject(:patron) do
    described_class.new(
      {
        key: '1',
        fields: fields
      }.with_indifferent_access
    )
  end

  let(:fields) do
    {
      firstName: 'Student',
      lastName: 'Borrower',
      standing: {
        key: 'DELINQUENT'
      },
      profile: {
        key: 'MXFEE-FUN',
        fields: {
        }
      },
      privilegeExpiresDate: nil,
      address1: [
        { 'resource' => '/user/patron/address1',
          'key' => '3',
          'fields' =>
           { 'code' => { 'resource' => '/policy/patronAddress1', 'key' => 'LINE1' },
             'data' => '152B Green Library, 557 Escondido Mall' } },
        { 'resource' => '/user/patron/address1',
          'key' => '4',
          'fields' =>
           { 'code' => { 'resource' => '/policy/patronAddress1', 'key' => 'LINE2' },
             'data' => 'Stanford, CA 94305-6063' } },
        { 'resource' => '/user/patron/address1',
          'key' => '8',
          'fields' =>
           { 'code' => { 'resource' => '/policy/patronAddress1', 'key' => 'EMAIL' },
             'data' => 'superuser1@stanford.edu' } }
      ]
    }
  end

  it 'has a first name' do
    expect(patron.first_name).to eq 'Student'
  end

  it 'has a last name' do
    expect(patron.last_name).to eq 'Borrower'
  end

  it 'has an email' do
    expect(patron.email).to eq 'superuser1@stanford.edu'
  end

  context 'when there is not an email resource in the patron record' do
    before do
      fields[:address1] = []
    end

    it 'does not have an email' do
      expect(patron.email).to be_nil
    end
  end

  it 'has a standing' do
    expect(patron.standing).to eq 'DELINQUENT'
  end

  it 'is in good standing' do
    expect(patron.good_standing?).to be true
  end

  it 'is a fee borrower' do
    expect(patron.fee_borrower?).to be true
  end

  it 'has a display name' do
    expect(patron.display_name).to eq 'Student Borrower'
  end

  describe '#holds' do
    it 're-requests the patron information with holds' do
      allow(described_class).to receive(:find_by).with(patron_key: '1', with_holds: true).and_return(
        instance_double(described_class, hold_record_list: [{}, {}, {}])
      ).once

      expect(patron.holds).to have_attributes(size: 3)
      expect(patron.holds).to have_attributes(size: 3)
    end

    describe 'when it already retrieved the holds' do
      before do
        patron.fields['holdRecordList'] = [{}, {}, {}]
      end

      it 'uses the existing data' do
        expect(described_class).not_to receive(:find_by)
        expect(patron.holds).to have_attributes(size: 3)
      end
    end
  end
end
