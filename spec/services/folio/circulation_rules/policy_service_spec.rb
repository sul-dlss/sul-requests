# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::CirculationRules::PolicyService do
  context 'with the actual rules' do
    it 'is parseable' do
      expect { described_class.rules }.not_to raise_error
    end

    context 'with a SAL3 book' do
      let(:item) { instance_double(Folio::Item, material_type:, loan_type:, effective_location:) }
      let(:material_type) do
        Folio::MaterialType.new(**Folio::Types.instance.get_type('material_types').find do |t|
                                    t['name'] == 'book'
                                  end.slice('id', 'name'))
      end
      let(:loan_type) do
        Folio::LoanType.new(Folio::Types.instance.get_type('loan_types').find do |t|
                              t['name'] == 'Can circulate'
                            end.slice('id', 'name'))
      end
      let(:effective_location) do
        Folio::Location.from_hash(
          (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'SAL3-STACKS' }).merge(
            'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
            'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
            'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'SAL3' }
          )
        )
      end

      it 'is pageable' do
        expect(described_class.instance.item_request_policy(item)['requestTypes']).to include 'Page'
      end
    end

    context 'with a PAGE-GR book' do
      let(:item) { instance_double(Folio::Item, material_type:, loan_type:, effective_location:) }
      let(:material_type) do
        Folio::MaterialType.new(**Folio::Types.instance.get_type('material_types').find do |t|
                                    t['name'] == 'book'
                                  end.slice('id', 'name'))
      end
      let(:loan_type) do
        Folio::LoanType.new(Folio::Types.instance.get_type('loan_types').find do |t|
                              t['name'] == 'Non-circulating'
                            end.slice('id', 'name'))
      end
      let(:effective_location) do
        Folio::Location.from_hash(
          (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'SAL3-PAGE-GR' }).merge(
            'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
            'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
            'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'SAL3' }
          )
        )
      end

      it 'is pageable' do
        expect(described_class.instance.item_request_policy(item)['requestTypes']).to include 'Page'
      end
    end

    context 'with a BUS-CRES book' do
      let(:item) { instance_double(Folio::Item, material_type:, loan_type:, effective_location:) }
      let(:material_type) do
        Folio::MaterialType.new(**Folio::Types.instance.get_type('material_types').find do |t|
                                    t['name'] == 'book'
                                  end.slice('id', 'name'))
      end
      let(:loan_type) do
        Folio::LoanType.new(Folio::Types.instance.get_type('loan_types').find do |t|
                              t['name'] == 'Can circulate'
                            end.slice('id', 'name'))
      end
      let(:effective_location) do
        Folio::Location.from_hash(
          (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'BUS-CRES' }).merge(
            'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
            'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'GSB' },
            'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'BUSINESS' }
          )
        )
      end

      it 'is not requestable' do
        expect(described_class.instance.item_request_policy(item)['requestTypes']).to be_blank
      end
    end
  end

  describe '#item_rule' do
    subject(:service) { described_class.new(rules:) }

    let(:rules) do
      [
        Folio::CirculationRules::Rule.new(
          { 'material-type' => 'book', 'loan-type' => '12hour', 'location-campus' => 'c365047a-51f2-45ce-8601-e421ca3615c5',
            'group' => 'courtesy' }, 'books-courtesy-sul'
        ),
        Folio::CirculationRules::Rule.new({ 'material-type' => 'book', 'group' => 'courtesy' }, 'group-rule'),
        Folio::CirculationRules::Rule.new(
          { 'material-type' => 'book', 'loan-type' => '7day',
            'location-campus' => 'c365047a-51f2-45ce-8601-e421ca3615c5' }, 'books-7day-sul'
        ),
        Folio::CirculationRules::Rule.new(
          { 'material-type' => 'book', 'location-campus' => 'c365047a-51f2-45ce-8601-e421ca3615c5',
            'location-library' => 'f6b5519e-88d9-413e-924d-9ed96255f72e' }, 'books-green'
        ),
        Folio::CirculationRules::Rule.new({ 'material-type' => 'book', 'loan-type' => 'reserves' }, 'books-reserves'),
        Folio::CirculationRules::Rule.new({ 'material-type' => { not: ['book'] }, 'loan-type' => 'reserves' }, 'other-reserves'),
        Folio::CirculationRules::Rule.new({ 'material-type' => 'book' }, 'books'),
        Folio::CirculationRules::Rule.new({ 'material-type' => { or: ['book', 'microform'] } }, 'book-or-microform'),
        Folio::CirculationRules::Rule.new({ 'location-library' => 'fe87087a-108b-4771-8ab9-5a4a5fc40960' }, 'ars'),
        Folio::CirculationRules::Rule.new({}, 'fallback')
      ]
    end

    let(:item) { instance_double(Folio::Item) }

    context 'when no rules match the item' do
      before do
        allow(item).to receive_messages(
          material_type: Folio::MaterialType.new(id: 'multimedia', name: 'Multimedia'),
          loan_type: Folio::LoanType.new(id: '7hour'),
          effective_location: Folio::Location.from_hash(
            (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'MEDIA-CAGE' }).merge(
              'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
              'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
              'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'MEDIA-CENTER' }
            )
          )
        )
      end

      it 'returns the fallback rule' do
        expect(service.item_rule(item).policy).to eq('fallback')
      end
    end

    context 'when courtesy patron group' do
      subject(:service) { described_class.new(rules:, patron_groups: ['courtesy']) }

      before do
        allow(item).to receive_messages(
          material_type: Folio::MaterialType.new(id: 'book', name: 'Book'),
          loan_type: Folio::LoanType.new(id: '7day'),
          effective_location: Folio::Location.from_hash(
            (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'MEDIA-STACKS' }).merge(
              'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
              'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
              'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'MEDIA-CENTER' }
            )
          )
        )
      end

      it 'returns the matching rule' do
        expect(service.item_rule(item).policy).to eq('group-rule')
      end
    end

    context 'when courtesy patron group and location is green' do
      subject(:service) { described_class.new(rules:, patron_groups: ['courtesy']) }

      before do
        allow(item).to receive_messages(
          material_type: Folio::MaterialType.new(id: 'book', name: 'Book'),
          loan_type: Folio::LoanType.new(id: '12hour'),
          effective_location: Folio::Location.from_hash(
            (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'GRE-STACKS' }).merge(
              'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
              'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
              'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'GREEN' }
            )
          )
        )
      end

      it 'returns the matching rule' do
        expect(service.item_rule(item).policy).to eq('books-courtesy-sul')
      end
    end

    context 'when a single rule matches the item' do
      before do
        allow(item).to receive_messages(
          material_type: Folio::MaterialType.new(id: 'microform', name: 'Microform'),
          loan_type: Folio::LoanType.new(id: '12hour'),
          effective_location: Folio::Location.from_hash(
            (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'MEDIA-STACKS' }).merge(
              'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
              'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
              'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'MEDIA-CENTER' }
            )
          )
        )
      end

      it 'returns the matching rule' do
        expect(service.item_rule(item).policy).to eq('book-or-microform')
      end
    end

    context 'when multiple rules match the item' do
      before do
        allow(item).to receive_messages(
          material_type: Folio::MaterialType.new(id: 'book', name: 'Books'),
          loan_type: Folio::LoanType.new(id: '7day'),
          effective_location: Folio::Location.from_hash(
            (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'GRE-STACKS' }).merge(
              'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
              'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
              'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'GREEN' }
            )
          )
        )
      end

      it 'returns the highest priority matching rule' do
        expect(service.item_rule(item).policy).to eq('books-7day-sul')
      end
    end

    context 'when a rule applies to a library containing the item location' do
      before do
        allow(item).to receive_messages(
          material_type: Folio::MaterialType.new(id: 'multimedia', name: 'Multimedia'),
          loan_type: Folio::LoanType.new(id: 'rr'),
          effective_location: Folio::Location.from_hash(
            (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'ARS-REF' }).merge(
              'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
              'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
              'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'ARS' }
            )
          )
        )
      end

      it 'returns the matching rule' do
        expect(service.item_rule(item).policy).to eq('ars')
      end
    end
  end

  describe 'policy querying' do
    subject(:service) { described_class.new(rules:, policies:) }

    let(:rules) do
      [
        Folio::CirculationRules::Rule.new(
          { 'loan-type' => 'can-circ' },
          {
            'request' => 'allow-all',
            'loan' => '3day-norenew-15mingrace',
            'lost-item' => '30fee',
            'notice' => 'short',
            'overdue' => '150-1050'
          }
        ),
        Folio::CirculationRules::Rule.new(
          {},
          {
            'request' => 'no-requests',
            'loan' => '28day-norenew-1daygrace',
            'lost-item' => 'norepl',
            'notice' => 'default',
            'overdue' => 'nofine'
          }
        )
      ]
    end

    let(:policies) do
      {
        request: {
          'allow-all' => 'Allow all requests',
          'no-requests' => 'No requests allowed'
        },
        loan: {
          '3day-norenew-15mingrace' => '3 day loan, no renewals, 15 minute grace period',
          '28day-norenew-1daygrace' => '28 day loan, no renewals, 1 day grace period'
        },
        'lost-item': {
          'norepl' => 'No replacement',
          '30fee' => '$30 lost fee policy'
        },
        notice: {
          'short' => 'Short-term loan notice policy',
          'default' => 'Default notice policy'
        },
        overdue: {
          '150-1050' => '1.50/10.50 overdue fine',
          'nofine' => 'No fines policy'
        }
      }
    end

    let(:item) { instance_double(Folio::Item) }

    before do
      allow(item).to receive_messages(
        material_type: Folio::MaterialType.new(id: 'book', name: 'Books'),
        loan_type: Folio::LoanType.new(id: 'can-circ'),
        effective_location: Folio::Location.from_hash(
          (Folio::Types.instance.get_type('locations').find { |t| t['code'] == 'GRE-STACKS' }).merge(
            'institution' => Folio::Types.instance.get_type('institutions').find { |t| t['code'] == 'SU' },
            'campus' => Folio::Types.instance.get_type('campuses').find { |t| t['code'] == 'SUL' },
            'library' => Folio::Types.instance.get_type('libraries').find { |t| t['code'] == 'GREEN' }
          )
        )
      )
    end

    it 'can fetch the request policy for an item' do
      expect(service.item_request_policy(item)).to eq('Allow all requests')
    end

    it 'can fetch the loan policy for an item' do
      expect(service.item_loan_policy(item)).to eq('3 day loan, no renewals, 15 minute grace period')
    end

    it 'can fetch the lost policy for an item' do
      expect(service.item_lost_policy(item)).to eq('$30 lost fee policy')
    end

    it 'can fetch the notice policy for an item' do
      expect(service.item_notice_policy(item)).to eq('Short-term loan notice policy')
    end

    it 'can fetch the overdue policy for an item' do
      expect(service.item_overdue_policy(item)).to eq('1.50/10.50 overdue fine')
    end
  end
end
