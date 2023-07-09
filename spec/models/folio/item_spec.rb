# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Item do
  describe '.from_hash' do
    subject { described_class.from_hash(JSON.parse(data)) }

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
              "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
              "libraryId": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
              "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
              "code": "SAL3-STACKS",
              "discoveryDisplayName": "Off-campus storage",
              "name": "SAL3 Stacks"
            },
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
              "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
              "libraryId": "f6b5519e-88d9-413e-924d-9ed96255f72e",
              "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
              "code": "GRE-STACKS",
              "discoveryDisplayName": "Green Library Stacks",
              "name": "Green Stacks"
            },
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "temporaryLoanTypeId": null
          }
        JSON
      end

      it { is_expected.to be_instance_of described_class }
    end
  end
end
