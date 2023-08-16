# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Item do
  subject(:item) { described_class.from_hash(JSON.parse(data)) }

  describe '.from_hash' do
    context 'from a record without a barcode or callnumber' do
      let(:data) do
        <<~JSON
          {
            "barcode": null,
            "status": {
              "name": "On order"
            },
            "materialType": null,
            "chronology": null,
            "enumeration": null,
            "effectiveCallNumberComponents": {
              "callNumber": null
            },
            "notes": [],
            "effectiveLocation": {
              "id": "1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2",
              "campus": {
                "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                "code": "SUL"
              },
              "library": {
                "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                "code": "SAL3"
              },
              "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
              "code": "SAL3-STACKS",
              "discoveryDisplayName": "Off-campus storage",
              "name": "SAL3 Stacks",
              "details": {}
            },
            "permanentLocation": { "id": "uuid", "code": "SAL3-STACKS" },
            "holdingsRecord": { "effectiveLocation": { "code": "SAL3-STACKS" } },
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "temporaryLoanTypeId": null
          }
        JSON
      end

      it { is_expected.to be_instance_of described_class }
    end

    context 'from a full record' do
      let(:data) do
        <<~JSON
          {
            "barcode": "36105124065330",
            "status": {
              "name": "Available"
            },
            "materialType": null,
            "chronology": null,
            "enumeration": null,
            "effectiveCallNumberComponents": {
              "callNumber": "SB270 .E8 A874 2007"
            },
            "notes": [
              {
                "note": "EDI receipt; tf:GREEN 07/03/14 batch; tf:SAL 07/28/17 batch",
                "itemNoteType": null
              }
            ],
            "effectiveLocation": {
              "id": "4573e824-9273-4f13-972f-cff7bf504217",
              "campus": {
                "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                "code": "SUL"
              },
              "library": {
                "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                "code": "GREEN"
              },
              "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
              "code": "GRE-STACKS",
              "discoveryDisplayName": "Green Library Stacks",
              "name": "Green Stacks",
              "details": {}
            },
            "permanentLocation": { "id": "uuid", "code": "SAL3-STACKS" },
            "holdingsRecord": { "effectiveLocation": { "code": "SAL3-STACKS" } },
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "temporaryLoanTypeId": null
          }
        JSON
      end

      it { is_expected.to be_instance_of described_class }
    end
  end

  describe '#status_class' do
    context 'with a non-circulating item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
            "notes": []
          }
        JSON
      end

      it 'is noncirc' do
        expect(item.status_class).to eq('available noncirc')
      end
    end

    context 'with a paged item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocationId": "#{Folio::Types.locations.find_by(code: 'SAL3-STACKS').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'SAL3-STACKS').id}",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is deliver-from-offsite' do
        expect(item.status_class).to eq('deliver-from-offsite')
      end
    end

    context 'with a non-circulating paged item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocationId": "#{Folio::Types.locations.find_by(code: 'SAL3-PAGE-SP').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'SAL3-PAGE-SP').id}",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is deliver-from-offsite AND noncirc' do
        expect(item.status_class).to eq('deliver-from-offsite noncirc')
      end
    end

    context 'with a circulating item with the status Available' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is available' do
        expect(item.status_class).to eq('available')
      end
    end

    context 'with an item that is checked out' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Checked out" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is unavailable' do
        expect(item.status_class).to eq('unavailable')
      end
    end
  end

  describe '#status_text' do
    context 'with a non-circulating item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
            "notes": []
          }
        JSON
      end

      it 'is noncirc' do
        expect(item.status_text).to eq('In-library use')
      end
    end

    context 'with a paged item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'SAL3-STACKS').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'SAL3-STACKS').id}",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is deliver-from-offsite' do
        expect(item.status_text).to eq('Available')
      end
    end

    context 'with a non-circulating paged item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'SAL3-PAGE-SP').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'SAL3-PAGE-SP').id}",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is deliver-from-offsite AND noncirc' do
        expect(item.status_text).to eq('In-library use')
      end
    end

    context 'with a circulating item with the status Available' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is available' do
        expect(item.status_text).to eq('Available')
      end
    end

    context 'with an item that is checked out' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Checked out" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "effectiveLocationId": "#{Folio::Types.locations.find_by(code: 'GRE-STACKS').id}",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is unavailable' do
        expect(item.status_text).to eq('Unavailable')
      end
    end
  end
end
