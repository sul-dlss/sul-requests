# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Item do
  subject(:item) { described_class.from_hash(JSON.parse(data)) }

  let(:patron) { Folio::Patron.new({ 'id' => 'patron_id', 'patronGroup' => patron_group_id, 'active' => true }) }

  before do
    allow(Folio::CirculationRules::PolicyService.instance).to receive(:item_request_policy).and_return(
      {
        'requestTypes' => %w[Page Hold Recall]
      }
    )
  end

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
            "queueTotalLength": 0,
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
            "queueTotalLength": 0,
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

    context 'from the FOLIO item-storage response' do
      let(:data) do
        <<~JSON
          {
            "barcode": "36105124065330",
            "status": {
              "name": "Available"
            },
            "queueTotalLength": 0,
            "materialTypeId": null,
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
            "effectiveLocationId": "4573e824-9273-4f13-972f-cff7bf504217",
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "temporaryLoanTypeId": null
          }
        JSON
      end

      it { is_expected.to be_instance_of described_class }
    end
  end

  describe '#status_class' do
    let(:gre_stacks) do
      <<~JSON
        {
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
        }
      JSON
    end

    let(:page_sp) do
      <<~JSON
          {
          "id": "3cbd5559-5ca9-473e-8d7d-98a67bff29f5",
          "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
          "libraryId": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
          "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
          "code": "SAL3-PAGE-SP",
          "discoveryDisplayName": "For use in Special Collections Reading Room",
          "name": "SAL3 PAGE-SP",
          "servicePoints": [
            {
              "id": "3a306665-eec7-4a40-8f4d-608585b2a394",
              "code": "SAL3",
              "pickupLocation": false
            }
          ],
          "library": {
            "id": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
            "code": "SAL3"
          },
          "campus": {
            "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
            "code": "SUL"
          },
          "details": {
            "pageAeonSite": null,
            "pageMediationGroupKey": null,
            "pageServicePoints": [
              {
                "id": "0e924af7-785c-46eb-a5e2-060394822016",
                "code": "SPEC",
                "name": "Special Collections Desk"
              }
            ],
            "scanServicePointCode": null,
            "availabilityClass": "Offsite"
          }
        }
      JSON
    end

    let(:sal3_stacks) do
      <<~JSON
        {
          "id": "1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2",
          "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
          "libraryId": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
          "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
          "code": "SAL3-STACKS",
          "discoveryDisplayName": "Stacks",
          "name": "SAL3 Stacks",
          "servicePoints": [
            {
              "id": "3a306665-eec7-4a40-8f4d-608585b2a394",
              "code": "SAL3",
              "pickupLocation": false
            }
          ],
          "library": {
            "id": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
            "code": "SAL3"
          },
          "campus": {
            "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
            "code": "SUL"
          },
          "details": {
            "availabilityClass": "Offsite"
          }
        }
      JSON
    end

    context 'with a non-circulating item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{gre_stacks},
            "effectiveLocation": #{gre_stacks},
            "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
            "notes": []
          }
        JSON
      end

      it 'is noncirc' do
        expect(item.status_class).to eq('available noncirc')
      end
    end

    context 'with aged to lost item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Aged to lost" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{sal3_stacks},
            "effectiveLocation": #{sal3_stacks},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is hold-recall' do
        expect(item.status_class).to eq('hold-recall')
      end
    end

    context 'with a paged item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{sal3_stacks},
            "effectiveLocation": #{sal3_stacks},
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
            "permanentLocation": #{page_sp},
            "effectiveLocation": #{page_sp},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      let(:patron_group_id) { Folio::Types.patron_groups.find_by(group: 'courtesy').id }

      it 'is deliver-from-offsite AND noncirc' do
        expect(item.status_class).to eq('deliver-from-offsite noncirc')
      end

      it 'is pageable' do
        expect(item.holdable?).to be(false)
        expect(item.recallable?).to be(false)
        expect(item.pageable?).to be(true)
      end

      it 'is pageable for courtsey' do
        expect(item.holdable?(patron)).to be(false)
        expect(item.recallable?(patron)).to be(false)
        expect(item.pageable?(patron)).to be(true)
      end
    end

    context 'with a circulating item with the status Available' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{gre_stacks},
            "effectiveLocation": #{gre_stacks},
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
            "permanentLocation": #{gre_stacks},
            "effectiveLocation": #{gre_stacks},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end
      let(:patron_group_id) { Folio::Types.patron_groups.find_by(group: 'courtesy').id }

      it 'is a hold recall' do
        expect(item.status_class).to eq('hold-recall')
      end

      it 'is recallable' do
        expect(item.recallable?).to be(true)
      end

      it 'is not recallable for courtesy, but is holdable' do
        expect(item.recallable?(patron)).to be(false)
        expect(item.holdable?(patron)).to be(true)
      end
    end
  end

  describe '#status_text' do
    let(:gre_stacks) do
      <<~JSON
        {
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
        }
      JSON
    end

    let(:page_sp) do
      <<~JSON
          {
          "id": "3cbd5559-5ca9-473e-8d7d-98a67bff29f5",
          "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
          "libraryId": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
          "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
          "code": "SAL3-PAGE-SP",
          "discoveryDisplayName": "For use in Special Collections Reading Room",
          "name": "SAL3 PAGE-SP",
          "servicePoints": [
            {
              "id": "3a306665-eec7-4a40-8f4d-608585b2a394",
              "code": "SAL3",
              "pickupLocation": false
            }
          ],
          "library": {
            "id": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
            "code": "SAL3"
          },
          "campus": {
            "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
            "code": "SUL"
          },
          "details": {
            "pageAeonSite": null,
            "pageMediationGroupKey": null,
            "pageServicePoints": [
              {
                "id": "0e924af7-785c-46eb-a5e2-060394822016",
                "code": "SPEC",
                "name": "Special Collections Desk"
              }
            ],
            "scanServicePointCode": null,
            "availabilityClass": "Offsite"
          }
        }
      JSON
    end

    let(:sal3_stacks) do
      <<~JSON
        {
          "id": "1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2",
          "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
          "libraryId": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
          "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
          "code": "SAL3-STACKS",
          "discoveryDisplayName": "Stacks",
          "name": "SAL3 Stacks",
          "servicePoints": [
            {
              "id": "3a306665-eec7-4a40-8f4d-608585b2a394",
              "code": "SAL3",
              "pickupLocation": false
            }
          ],
          "library": {
            "id": "ddd3bce1-9f8f-4448-8d6d-b6c1b3907ba9",
            "code": "SAL3"
          },
          "campus": {
            "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
            "code": "SUL"
          },
          "details": {
            "availabilityClass": "Offsite"
          }
        }
      JSON
    end

    context 'with a non-circulating item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{gre_stacks},
            "effectiveLocation": #{gre_stacks},
            "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
            "notes": []
          }
        JSON
      end

      it 'is noncirc' do
        expect(item.status_text).to eq('In-library use only')
      end
    end

    context 'with a paged item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{sal3_stacks},
            "effectiveLocation": #{sal3_stacks},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is deliver-from-offsite' do
        expect(item.status_text).to eq('Available')
      end
    end

    context 'with aged to lost item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Aged to lost" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{sal3_stacks},
            "effectiveLocation": #{sal3_stacks},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is hold-recall' do
        expect(item.status_text).to eq('Checked out')
      end
    end

    context 'with a non-circulating paged item' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{page_sp},
            "effectiveLocation": #{page_sp},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is deliver-from-offsite AND noncirc' do
        expect(item.status_text).to eq('In-library use only')
      end
    end

    context 'with a circulating item with the status Available' do
      let(:data) do
        <<~JSON
          {
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{gre_stacks},
            "effectiveLocation": #{gre_stacks},
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
            "permanentLocation": #{gre_stacks},
            "effectiveLocation": #{gre_stacks},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is checked out' do
        expect(item.status_text).to eq('Checked out')
      end
    end
  end

  describe '#suppressed_from_discovery?' do
    let(:gre_stacks) do
      <<~JSON
        {
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
        }
      JSON
    end

    context 'with a suppressed item' do
      let(:data) do
        <<~JSON
          {
            "discoverySuppress": true,
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{gre_stacks},
            "effectiveLocation": #{gre_stacks},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is suppressed' do
        expect(item.suppressed_from_discovery?).to be(true)
      end
    end

    context 'with an unsuppressed item' do
      let(:data) do
        <<~JSON
          {
            "discoverySuppress": false,
            "status": { "name": "Available" },
            "materialType": { "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892", "name": "book" },
            "permanentLocation": #{gre_stacks},
            "effectiveLocation": #{gre_stacks},
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "notes": []
          }
        JSON
      end

      it 'is not suppressed' do
        expect(item.suppressed_from_discovery?).to be(false)
      end
    end
  end
end
