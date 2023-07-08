# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Instance do
  subject(:data) { described_class.fetch(request) }

  let(:request) { build(:request) }
  let(:instance_response) do
    <<~JSON
      {
        "id": "57550106-e809-5a43-92da-1503d84dcc18",
        "title": "Coffee / Nebiyu Assefa and Joanna Brown",
        "identifiers": [
          {
            "value": "9780955506000",
            "identifierTypeObject": {
              "name": "ISBN"
            },
            "identifierTypeId": "8261054f-be78-422d-bd51-4ed9f33c3422"
          },
          {
            "value": "095550600X",
            "identifierTypeObject": {
              "name": "ISBN"
            },
            "identifierTypeId": "8261054f-be78-422d-bd51-4ed9f33c3422"
          },
          {
            "value": "(OCoLC-M)213487023",
            "identifierTypeObject": {
              "name": "System control number"
            },
            "identifierTypeId": "7e591197-f335-4afb-bc6d-a6d76ca3bace"
          },
          {
            "value": "(OCoLC-I)276038905",
            "identifierTypeObject": {
              "name": "System control number"
            },
            "identifierTypeId": "7e591197-f335-4afb-bc6d-a6d76ca3bace"
          },
          {
            "value": "cis5764143",
            "identifierTypeObject": {
              "name": "System control number"
            },
            "identifierTypeId": "7e591197-f335-4afb-bc6d-a6d76ca3bace"
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
              "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
              "libraryId": "f6b5519e-88d9-413e-924d-9ed96255f72e",
              "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
              "code": "GRE-STACKS",
              "discoveryDisplayName": "Green Library Stacks",
              "name": "Green Stacks"
            }
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

    it { is_expected.to eq '9780955506000; 095550600X' }
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
                "identifierTypeObject": {
                  "name": "System control number"
                },
                "identifierTypeId": "7e591197-f335-4afb-bc6d-a6d76ca3bace"
              },
              {
                "value": "(OCoLC-I)755035981",
                "identifierTypeObject": {
                  "name": "System control number"
                },
                "identifierTypeId": "7e591197-f335-4afb-bc6d-a6d76ca3bace"
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
                  "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
                  "libraryId": "5b61a365-6b39-408c-947d-f8861a7ba8ae",
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec U-Archives"
                }
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
                  "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
                  "libraryId": "5b61a365-6b39-408c-947d-f8861a7ba8ae",
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives"
                }
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
                  "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
                  "libraryId": "5b61a365-6b39-408c-947d-f8861a7ba8ae",
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives"
                }
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
                  "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5",
                  "libraryId": "5b61a365-6b39-408c-947d-f8861a7ba8ae",
                  "institutionId": "8d433cdd-4e8f-4dc1-aa24-8a4ddb7dc929",
                  "code": "SPEC-SAL3-U-ARCHIVES",
                  "discoveryDisplayName": "University Archives",
                  "name": "Spec SAL3 U-Archives"
                }
              }
            ]
          }
        JSON
      end

      it { is_expected.to eq 'http://www.oac.cdlib.org/findaid/ark:/13030/kt7b69s0dh' }
    end
  end

  describe '#holdings' do
    pending 'not implemented yet'
  end
end
