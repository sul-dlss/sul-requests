# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::BibData do
  subject(:data) { described_class.new(request) }

  let(:request) { build(:request) }
  let(:labels_response) do
    <<~JSON
      [ {
          "id" : "3363cdb1-e644-446c-82a4-dc3a1d4395b9",
          "name" : "cartographic dataset",
          "code" : "crd",
          "source" : "rdacontent",
          "metadata" : {
            "createdDate" : "2023-02-08T20:08:31.267+00:00",
            "updatedDate" : "2023-02-08T20:08:31.267+00:00"
          }
        },{
          "id" : "30fffe0e-e985-4144-b2e2-1e8179bdb41f",
          "name" : "unspecified",
          "code" : "zzz",
          "source" : "rdacontent",
          "metadata" : {
            "createdDate" : "2023-02-08T20:08:30.780+00:00",
            "updatedDate" : "2023-02-08T20:08:30.780+00:00"
          }
        } ]
    JSON
  end
  let(:instance_response) do
    <<~JSON
      {
        "id": "57550106-e809-5a43-92da-1503d84dcc18",
        "_version": "1",
        "hrid": "a6959652",
        "source": "MARC",
        "title": "Coffee / Nebiyu Assefa and Joanna Brown",
        "administrativeNotes": ["MONORECUnit/14 January 2008/ejh", "MARCUnit/1 February 2008/rjrCoutts"],
        "indexTitle": "Coffee",
        "parentInstances": [],
        "childInstances": [],
        "isBoundWith": false,
        "alternativeTitles": [],
        "editions": [],
        "series": [],
        "identifiers": [{
          "identifierTypeId": "8261054f-be78-422d-bd51-4ed9f33c3422",
          "value": "9780955506000"
        }, {
          "identifierTypeId": "8261054f-be78-422d-bd51-4ed9f33c3422",
          "value": "095550600X"
        }, {
          "identifierTypeId": "7e591197-f335-4afb-bc6d-a6d76ca3bace",
          "value": "(OCoLC-M)213487023"
        }, {
          "identifierTypeId": "7e591197-f335-4afb-bc6d-a6d76ca3bace",
          "value": "(OCoLC-I)276038905"
        }, {
          "identifierTypeId": "7e591197-f335-4afb-bc6d-a6d76ca3bace",
          "value": "cis5764143"
        }],
        "contributors": [{
          "contributorNameTypeId": "2b94c631-fca9-4892-a730-03ee529ffe2a",
          "name": "Assefa, Nebiuy",
          "contributorTypeId": "9f0a2cf0-7a9b-45a2-a403-f68d2850d07c",
          "contributorTypeText": "Contributor",
          "authorityId": null,
          "primary": true
        }, {
          "contributorNameTypeId": "2b94c631-fca9-4892-a730-03ee529ffe2a",
          "name": "Brown, Joanna",
          "contributorTypeId": "9f0a2cf0-7a9b-45a2-a403-f68d2850d07c",
          "contributorTypeText": "Contributor",
          "authorityId": null,
          "primary": false
        }],
        "subjects": ["Coffee Ethiopia Pictorial works", "Coffee growers Ethiopia Social conditions Pictorial works", "Ethiopia Social life and customs Pictorial works"],
        "classifications": [{
          "classificationNumber": "SB270.E8 A874 2007",
          "classificationTypeId": "ce176ace-a53e-4b4d-aa89-725ed7b2edac"
        }],
        "publication": [{
          "publisher": "Jozart Press",
          "place": "[Leeds, UK?]",
          "dateOfPublication": "c2007",
          "role": null
        }],
        "publicationFrequency": [],
        "publicationRange": [],
        "electronicAccess": [],
        "instanceTypeId": "30fffe0e-e985-4144-b2e2-1e8179bdb41f",
        "instanceFormatIds": [],
        "physicalDescriptions": ["1 v. (unpaged) : chiefly ill. (some col.) ; 17 cm."],
        "languages": ["eng"],
        "notes": [{
          "instanceNoteTypeId": "6a2533a7-4de2-4e64-8466-074c2fa9308c",
          "note": "Paintings and sketches, Nebiyu Assefa; photography, Joanna Brown; design and editing, Joanna Brown--Colophon",
          "staffOnly": false
        }, {
          "instanceNoteTypeId": "6a2533a7-4de2-4e64-8466-074c2fa9308c",
          "note": "Ill. on lining papers",
          "staffOnly": false
        }],
        "modeOfIssuanceId": "9d18a02f-5897-4c31-9106-c9abb5c7ae8b",
        "catalogedDate": "2008-02-01",
        "previouslyHeld": false,
        "staffSuppress": false,
        "discoverySuppress": false,
        "statisticalCodeIds": [],
        "statusId": "9634a5ab-9228-4703-baf2-4d12ebc77d56",
        "statusUpdatedDate": "2023-05-06T19:44:23.625+0000",
        "metadata": {
          "createdDate": "2023-05-06T19:44:24.036+00:00",
          "createdByUserId": "3e2ed889-52f2-45ce-8a30-8767266f07d2",
          "updatedDate": "2023-05-06T19:44:24.036+00:00",
          "updatedByUserId": "3e2ed889-52f2-45ce-8a30-8767266f07d2"
        },
        "tags": {
          "tagList": []
        },
        "natureOfContentTermIds": [],
        "publicationPeriod": {
          "start": 2007
        },
        "precedingTitles": [],
        "succeedingTitles": []
      }
    JSON
  end
  let(:folio_client) do
    instance_double(FolioClient, resolve_to_instance_id: 'f283c765-3271-55af-bef4-c0e5eb6edd7a',
                                 find_instance: JSON.parse(instance_response),
                                 instance_types: JSON.parse(labels_response))
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
            "id" : "a1a88348-363f-5b41-9937-13584daae527",
            "_version" : "1",
            "hrid" : "a6307113",
            "source" : "MARC",
            "title" : "Stanford Research Institute records, 1947-1966",
            "administrativeNotes" : [ ],
            "indexTitle" : "Stanford research institute records,",
            "parentInstances" : [ ],
            "childInstances" : [ ],
            "isBoundWith" : false,
            "alternativeTitles" : [ ],
            "editions" : [ ],
            "series" : [ ],
            "identifiers" : [ {
              "identifierTypeId" : "7e591197-f335-4afb-bc6d-a6d76ca3bace",
              "value" : "(OCoLC-M)754864063"
            }, {
              "identifierTypeId" : "7e591197-f335-4afb-bc6d-a6d76ca3bace",
              "value" : "(OCoLC-I)755035981"
            } ],
            "contributors" : [ {
              "contributorNameTypeId" : "2e48e713-17f3-4c13-a9f8-23845bb210aa",
              "name" : "Stanford Research Institute",
              "contributorTypeId" : "9f0a2cf0-7a9b-45a2-a403-f68d2850d07c",
              "contributorTypeText" : "Contributor",
              "authorityId" : null,
              "primary" : true
            } ],
            "subjects" : [ "SRI International", "Academic-industrial collaboration United States", "Research institutes" ],
            "classifications" : [ {
              "classificationNumber" : "SC0801",
              "classificationTypeId" : "ce176ace-a53e-4b4d-aa89-725ed7b2edac"
            } ],
            "publication" : [ ],
            "publicationFrequency" : [ ],
            "publicationRange" : [ ],
            "electronicAccess" : [ {
              "uri" : "http://www.oac.cdlib.org/findaid/ark:/13030/kt7b69s0dh",
              "linkText" : null,
              "materialsSpecification" : "Finding aid available online",
              "publicNote" : null,
              "relationshipId" : "5bfe1b7b-f151-4501-8cfa-23b321d5cd1e"
            } ],
            "instanceTypeId" : "30fffe0e-e985-4144-b2e2-1e8179bdb41f",
            "instanceFormatIds" : [ ],
            "physicalDescriptions" : [ "1.5 linear feet" ],
            "languages" : [ "eng" ],
            "notes" : [ {
              "instanceNoteTypeId" : "c636881b-8927-4480-ad1b-8d7b27b4bbfe",
              "note" : "The Stanford Research Institute was organized in 1946 as an applied research center for industry and government. In 1970 it became independent from Stanford University and in 1977 changed its name to SRI International",
              "staffOnly" : false
            }, {
              "instanceNoteTypeId" : "10e2e11b-450f-45c8-b09b-0f819999966e",
              "note" : "Collection consists primarily of minutes of the Board of Directors and the Executive Committee, with some reports, financial statements, correspondence, memoranda, articles and brochures. Topics include research projects, financing, board membership, equipment needs, facility growth, and other administrative issues",
              "staffOnly" : false
            }, {
              "instanceNoteTypeId" : "6a2533a7-4de2-4e64-8466-074c2fa9308c",
              "note" : "These materials were originally sent to the university president's office",
              "staffOnly" : false
            }, {
              "instanceNoteTypeId" : "fda2f2e3-965f-4220-8a2b-93d35ce6d582",
              "note" : "Unpublished guide available",
              "staffOnly" : false
            } ],
            "modeOfIssuanceId" : "9d18a02f-5897-4c31-9106-c9abb5c7ae8b",
            "catalogedDate" : "2011-06-23",
            "previouslyHeld" : false,
            "staffSuppress" : false,
            "discoverySuppress" : false,
            "statisticalCodeIds" : [ ],
            "statusId" : "9634a5ab-9228-4703-baf2-4d12ebc77d56",
            "statusUpdatedDate" : "2023-05-06T18:34:51.080+0000",
            "metadata" : {
              "createdDate" : "2023-05-06T18:34:51.217+00:00",
              "createdByUserId" : "3e2ed889-52f2-45ce-8a30-8767266f07d2",
              "updatedDate" : "2023-05-06T18:34:51.217+00:00",
              "updatedByUserId" : "3e2ed889-52f2-45ce-8a30-8767266f07d2"
            },
            "tags" : {
              "tagList" : [ ]
            },
            "natureOfContentTermIds" : [ ],
            "precedingTitles" : [ ],
            "succeedingTitles" : [ ]
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
