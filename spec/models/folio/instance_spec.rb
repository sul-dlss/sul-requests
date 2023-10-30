# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Instance do
  subject(:data) { described_class.fetch(request) }

  let(:request) { build(:request) }
  let(:instance_response) do
    <<~JSON
      {
        "id": "57550106-e809-5a43-92da-1503d84dcc18",
        "hrid": "a6959652",
        "title": "Coffee / Nebiyu Assefa and Joanna Brown",
        "identifiers": [
          {
            "value": "9780955506000",
            "identifierTypeObject": {
              "name": "ISBN"
            }
          },
          {
            "value": "095550600X",
            "identifierTypeObject": {
              "name": "ISBN"
            }
          },
          {
            "value": "(OCoLC-M)213487023",
            "identifierTypeObject": {
              "name": "System control number"
            }
          },
          {
            "value": "(OCoLC-I)276038905",
            "identifierTypeObject": {
              "name": "System control number"
            }
          },
          {
            "value": "cis5764143",
            "identifierTypeObject": {
              "name": "System control number"
            }
          }
        ],
        "instanceType": {
          "name": "unspecified"
        },
        "contributors": [
          {
            "name": "Assefa, Nebiuy",
            "primary": true
          },
          {
            "name": "Brown, Joanna",
            "primary": false
          }
        ],
        "publication": [
          {
            "dateOfPublication": "c2007"
          }
        ],
        "electronicAccess": [],
        "items": [
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
            "permanentLocation": { "id": "uuid", "code": "GRE-STACKS" },
            "holdingsRecord": { "effectiveLocation": { "code": "GRE-STACKS" } },
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "temporaryLoanTypeId": null
          }
        ]
      }
    JSON
  end
  let(:folio_client) do
    instance_double(FolioClient, find_instance_by: JSON.parse(instance_response))
  end

  before do
    allow(FolioClient).to receive(:new).and_return(folio_client)
  end

  describe '#title' do
    subject { data.title }

    it { is_expected.to eq 'Coffee' }
  end

  describe '#author' do
    subject { data.author }

    it { is_expected.to eq 'Assefa, Nebiuy' }
  end

  describe '#pub_date' do
    subject { data.pub_date }

    it { is_expected.to eq 'c2007' }
  end

  describe '#format' do
    subject { data.format }

    it { is_expected.to eq 'unspecified' }
  end

  describe '#isbn' do
    subject { data.isbn }

    it { is_expected.to eq '9780955506000' }
  end

  describe '#view_url' do
    subject { data.view_url }

    it { is_expected.to eq 'https://searchworks.stanford.edu/view/6959652' }
  end

  describe '#finding_aid' do
    subject { data.finding_aid }

    it { is_expected.to be_nil }

    context 'with a finding aid' do
      let(:instance_response) do
        <<~JSON
          {
            "id": "a1a88348-363f-5b41-9937-13584daae527",
            "title": "Stanford Research Institute records, 1947-1966",
            "identifiers": [
              {
                "value": "(OCoLC-M)754864063",
                "identifierTypeObject": null
              },
              {
                "value": "(OCoLC-I)755035981",
                "identifierTypeObject": null
              }
            ],
            "instanceType": {
              "name": "unspecified"
            },
            "contributors": [
              {
                "name": "Stanford Research Institute",
                "primary": true
              }
            ],
            "publication": [],
            "electronicAccess": [
              {
                "materialsSpecification": "Finding aid available online",
                "uri": "http://www.oac.cdlib.org/findaid/ark:/13030/kt7b69s0dh"
              }
            ],
            "items": [
              {
                "barcode": "6307113-1001",
                "status": {
                  "name": "Available"
                },
                "materialType": null,
                "chronology": null,
                "enumeration": null,
                "effectiveCallNumberComponents": {
                  "callNumber": "SC0801"
                },
                "notes": [
                  {
                    "note": ".COMMENT. c:pew; removed from 2191 collection",
                    "itemNoteType": null
                  }
                ],
                "effectiveLocation": {
                  "id": "635d2ddc-c7a1-46ce-b46d-336f1384c4dc",
                  "campus": {
                    "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                    "code": "SUL"
                  },
                  "library": {
                    "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                    "code": "SPEC-COLL"
                  },
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec U-Archives",
                  "details": {}
                },
                "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
                "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
                "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
                "temporaryLoanTypeId": null
              },
              {
                "barcode": "36105116223418",
                "status": {
                  "name": "Available"
                },
                "materialType": null,
                "chronology": null,
                "enumeration": "BOX 1",
                "effectiveCallNumberComponents": {
                  "callNumber": "SC0801"
                },
                "notes": [],
                "effectiveLocation": {
                  "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                  "campus": {
                    "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                    "code": "SUL"
                  },
                  "library": {
                    "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                    "code": "SPEC-COLL"
                  },
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives",
                  "details": {}
                },
                "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
                "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
                "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
                "temporaryLoanTypeId": null
              },
              {
                "barcode": "36105116223426",
                "status": {
                  "name": "Available"
                },
                "materialType": null,
                "chronology": null,
                "enumeration": "BOX 2",
                "effectiveCallNumberComponents": {
                  "callNumber": "SC0801"
                },
                "notes": [],
                "effectiveLocation": {
                  "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                  "campus": {
                    "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                    "code": "SUL"
                  },
                  "library": {
                    "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                    "code": "SPEC-COLL"
                  },
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives",
                  "details": {}
                },
                "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
                "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
                "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
                "temporaryLoanTypeId": null
              },
              {
                "barcode": "36105116223434",
                "status": {
                  "name": "Available"
                },
                "materialType": null,
                "chronology": null,
                "enumeration": "BOX 3",
                "effectiveCallNumberComponents": {
                  "callNumber": "SC0801"
                },
                "notes": [],
                "effectiveLocation": {
                  "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                  "campus": {
                    "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                    "code": "SUL"
                  },
                  "library": {
                    "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                    "code": "SPEC-COLL"
                  },
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives",
                  "details": {}
                },
                "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
                "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
                "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
                "temporaryLoanTypeId": null
              }
            ]
          }
        JSON
      end

      it { is_expected.to eq 'http://www.oac.cdlib.org/findaid/ark:/13030/kt7b69s0dh' }
    end
  end

  describe '#holdings' do
    let(:instance_response) do
      <<~JSON
        {
          "id": "a1a88348-363f-5b41-9937-13584daae527",
          "title": "Stanford Research Institute records, 1947-1966",
          "identifiers": [
            {
              "value": "(OCoLC-M)754864063",
              "identifierTypeObject": null
            },
            {
              "value": "(OCoLC-I)755035981",
              "identifierTypeObject": null
            }
          ],
          "instanceType": {
            "name": "unspecified"
          },
          "contributors": [
            {
              "name": "Stanford Research Institute",
              "primary": true
            }
          ],
          "publication": [],
          "electronicAccess": [
            {
              "materialsSpecification": "Finding aid available online",
              "uri": "http://www.oac.cdlib.org/findaid/ark:/13030/kt7b69s0dh"
            }
          ],
          "items": [
            {
              "barcode": "6307113-1001",
              "status": {
                "name": "Available"
              },
              "materialType": null,
              "chronology": null,
              "enumeration": null,
              "effectiveCallNumberComponents": {
                "callNumber": "SC0801"
              },
              "notes": [
                {
                  "note": ".COMMENT. c:pew; removed from 2191 collection",
                  "itemNoteType": null
                }
              ],
              "effectiveLocation": {
                "id": "635d2ddc-c7a1-46ce-b46d-336f1384c4dc",
                "campus": {
                  "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                  "code": "SUL"
                },
                "library": {
                  "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                  "code": "SPEC-COLL"
                },
                "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                "code": "SPEC-U-ARCHIVES",
                "discoveryDisplayName": "University Archives",
                "name": "Spec U-Archives",
                "details": {}
              },
              "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
              "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
              "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
              "temporaryLoanTypeId": null
            },
            {
              "barcode": "36105116223418",
              "status": {
                "name": "Available"
              },
              "materialType": null,
              "chronology": null,
              "enumeration": "BOX 1",
              "effectiveCallNumberComponents": {
                "callNumber": "SC0801"
              },
              "notes": [],
              "effectiveLocation": {
                "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                "campus": {
                  "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                  "code": "SUL"
                },
                "library": {
                  "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                  "code": "SPEC-COLL"
                },
                "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                "code": "SPEC-SAL3-U-ARCHIVES",
                "discoveryDisplayName": "University Archives",
                "name": "Spec SAL3 U-Archives",
                "details": {}
              },
              "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
              "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
              "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
              "temporaryLoanTypeId": null
            },
            {
              "barcode": "36105116223426",
              "status": {
                "name": "Available"
              },
              "materialType": null,
              "chronology": null,
              "enumeration": "BOX 2",
              "effectiveCallNumberComponents": {
                "callNumber": "SC0801"
              },
              "notes": [],
              "effectiveLocation": {
                "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                "campus": {
                  "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                  "code": "SUL"
                },
                "library": {
                  "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                  "code": "SPEC-COLL"
                },
                "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                "code": "SPEC-SAL3-U-ARCHIVES",
                "discoveryDisplayName": "University Archives",
                "name": "Spec SAL3 U-Archives",
                "details": {}
              },
              "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
              "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
              "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
              "temporaryLoanTypeId": null
            },
            {
              "barcode": "36105116223434",
              "status": {
                "name": "Available"
              },
              "materialType": null,
              "chronology": null,
              "enumeration": "BOX 3",
              "effectiveCallNumberComponents": {
                "callNumber": "SC0801"
              },
              "notes": [],
              "effectiveLocation": {
                "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                "campus": {
                  "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                  "code": "SUL"
                },
                "library": {
                  "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                  "code": "SPEC-COLL"
                },
                "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                "code": "SPEC-SAL3-U-ARCHIVES",
                "discoveryDisplayName": "University Archives",
                "name": "Spec SAL3 U-Archives",
                "details": {}
              },
              "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
              "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
              "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
              "temporaryLoanTypeId": null
            }
          ]
        }
      JSON
    end

    it 'returns items' do
      expect(data.holdings.count).to eq 4
    end

    context 'with suppressed items' do
      let(:instance_response) do
        <<~JSON
          {
            "id": "a1a88348-363f-5b41-9937-13584daae527",
            "title": "Stanford Research Institute records, 1947-1966",
            "identifiers": [
              {
                "value": "(OCoLC-M)754864063",
                "identifierTypeObject": null
              },
              {
                "value": "(OCoLC-I)755035981",
                "identifierTypeObject": null
              }
            ],
            "instanceType": {
              "name": "unspecified"
            },
            "contributors": [
              {
                "name": "Stanford Research Institute",
                "primary": true
              }
            ],
            "publication": [],
            "electronicAccess": [
              {
                "materialsSpecification": "Finding aid available online",
                "uri": "http://www.oac.cdlib.org/findaid/ark:/13030/kt7b69s0dh"
              }
            ],
            "items": [
              {
                "barcode": "6307113-1001",
                "status": {
                  "name": "Available"
                },
                "materialType": null,
                "chronology": null,
                "enumeration": null,
                "effectiveCallNumberComponents": {
                  "callNumber": "SC0801"
                },
                "notes": [
                  {
                    "note": ".COMMENT. c:pew; removed from 2191 collection",
                    "itemNoteType": null
                  }
                ],
                "effectiveLocation": {
                  "id": "635d2ddc-c7a1-46ce-b46d-336f1384c4dc",
                  "campus": {
                    "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                    "code": "SUL"
                  },
                  "library": {
                    "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                    "code": "SPEC-COLL"
                  },
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec U-Archives",
                  "details": {}
                },
                "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
                "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
                "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
                "temporaryLoanTypeId": null
              },
              {
                "barcode": "36105116223418",
                "status": {
                  "name": "Available"
                },
                "materialType": null,
                "chronology": null,
                "enumeration": "BOX 1",
                "effectiveCallNumberComponents": {
                  "callNumber": "SC0801"
                },
                "notes": [],
                "effectiveLocation": {
                  "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                  "campus": {
                    "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                    "code": "SUL"
                  },
                  "library": {
                    "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                    "code": "SPEC-COLL"
                  },
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives",
                  "details": {}
                },
                "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
                "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
                "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
                "temporaryLoanTypeId": null
              },
              {
                "barcode": "36105116223426",
                "status": {
                  "name": "Available"
                },
                "materialType": null,
                "chronology": null,
                "enumeration": "BOX 2",
                "effectiveCallNumberComponents": {
                  "callNumber": "SC0801"
                },
                "notes": [],
                "effectiveLocation": {
                  "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                  "campus": {
                    "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                    "code": "SUL"
                  },
                  "library": {
                    "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                    "code": "SPEC-COLL"
                  },
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives",
                  "details": {}
                },
                "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
                "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
                "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
                "temporaryLoanTypeId": null
              },
              {
                "barcode": "36105116223434",
                "discoverySuppress": true,
                "status": {
                  "name": "Available"
                },
                "materialType": null,
                "chronology": null,
                "enumeration": "BOX 3",
                "effectiveCallNumberComponents": {
                  "callNumber": "SC0801"
                },
                "notes": [],
                "effectiveLocation": {
                  "id": "150b8273-b10b-4907-b43f-a3d4f89bc79f",
                  "campus": {
                    "id": "c365047a-51f2-45ce-8601-e421ca3615c5",
                    "code": "SUL"
                  },
                  "library": {
                    "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
                    "code": "SPEC-COLL"
                  },
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives",
                  "details": {}
                },
                "permanentLocation": { "id": "uuid", "code": "SPEC-STACKS" },
                "holdingsRecord": { "effectiveLocation": { "code": "SPEC-STACKS" } },
                "permanentLoanTypeId": "52d7b849-b6d8-4fb3-b2ab-a9b0eb41b6fd",
                "temporaryLoanTypeId": null
              }
            ]
          }
        JSON
      end

      it 'returns only the unsuppressed items' do
        expect(data.holdings.count).to eq 3
      end
    end
  end
end
