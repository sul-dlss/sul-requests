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
              "name": "OCLC"
            }
          },
          {
            "value": "(OCoLC-I)276038905",
            "identifierTypeObject": {
              "name": "OCLC"
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

  describe '#oclcn' do
    subject { data.oclcn }

    it { is_expected.to eq '213487023' }
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

  describe '#has parent_bound_withs on a single record' do 
    let(:instance_response) do
      <<~JSON
      {
        "id": "174c321e-29d1-536c-958c-6964243be3a3",
        "hrid": "a2279186",
        "title": "'Heart damage' in baled jute, by R.S. Finlow ...",
        "identifiers": [
          {
            "value": "agr19000123",
            "identifierTypeObject": {
              "name": "LCCN"
            }
          },
          {
            "value": "(Sirsi) ALK9201",
            "identifierTypeObject": {
              "name": "System control number"
            }
          },
          {
            "value": "(OCoLC-M)26059935",
            "identifierTypeObject": {
              "name": "OCLC"
            }
          },
          {
            "value": "(OCoLC-I)274765705",
            "identifierTypeObject": {
              "name": "OCLC"
            }
          }
        ],
        "holdingsRecords": [
          {
            "callNumber": "630.654 .I39M V.5:NO.2",
            "boundWithItem": {
              "hrid": "ai5488000_1_3",
              "effectiveCallNumberComponents": {
                "callNumber": "630.654 .I39M"
              },
              "volume": null,
              "enumeration": "V.5:NO.1",
              "instance": {
                "hrid": "a5488000",
                "title": "The gases of swamp rice soils ... / by W.H. Harrison ... and P.A. Subramania Aiyer ...",
                "items": [
                  {
                    "id": "1193e6b3-3bfc-5c51-b1ac-7ef347cdc46f",
                    "barcode": "36105026508924",
                    "discoverySuppress": false,
                    "volume": null,
                    "status": {
                      "name": "Available"
                    },
                    "dueDate": null,
                    "materialType": {
                      "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892",
                      "name": "book"
                    },
                    "chronology": null,
                    "enumeration": "V.4:NO.1",
                    "effectiveCallNumberComponents": {
                      "callNumber": "630.654 .I39M"
                    },
                    "boundWithHoldingsPerItem": [
                      {
                        "callNumber": "630.654 .I39M V.4:NO.3",
                        "instance": {
                          "title": "Soil gases. By J. Walter Leather ...",
                          "hrid": "a2307597"
                        }
                      },
                      {
                        "callNumber": "630.654 .I39M V.4:NO.2",
                        "instance": {
                          "title": "Soil temperatures, by J. Walter Leather ...",
                          "hrid": "a2307605"
                        }
                      },
                      {
                        "callNumber": "630.654 .I39M V.4:NO.5",
                        "instance": {
                          "title": "Some factors affecting the cooking of dholl (Cajanus indicus) / By B. Viswanath, T. Lakshmana Row, B.A., and P.A. Raghunathaswami Ayyangar ...",
                          "hrid": "a2285756"
                        }
                      }
                    ],
                    "notes": [
                      {
                        "note": "tf:SAL 09/23/04 batch; i:kej,8/22/2008",
                        "itemNoteType": null
                      }
                    ],
                    "effectiveLocation": {
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
                        "pageAeonSite": null,
                        "pageMediationGroupKey": null,
                        "pageServicePoints": [],
                        "scanServicePointCode": "SAL3",
                        "availabilityClass": "Offsite",
                        "searchworksTreatTemporaryLocationAsPermanentLocation": null
                      }
                    },
                    "permanentLocation": null,
                    "temporaryLocation": null,
                    "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
                    "temporaryLoanTypeId": null,
                    "holdingsRecord": {
                      "id": "08cc5111-4b66-52b3-ada5-9c7881427fac",
                      "effectiveLocation": {
                        "id": "1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2",
                        "code": "SAL3-STACKS",
                        "details": {
                          "pageAeonSite": null,
                          "pageMediationGroupKey": null,
                          "pageServicePoints": [],
                          "pagingSchedule": null,
                          "scanServicePointCode": "SAL3"
                        }
                      }
                    }
                  },
                  {
                    "id": "f947bd93-a1eb-5613-8745-1063f948c461",
                    "barcode": "36105026515499",
                    "discoverySuppress": false,
                    "volume": null,
                    "status": {
                      "name": "Available"
                    },
                    "dueDate": null,
                    "materialType": {
                      "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892",
                      "name": "book"
                    },
                    "chronology": null,
                    "enumeration": "V.5:NO.1",
                    "effectiveCallNumberComponents": {
                      "callNumber": "630.654 .I39M"
                    },
                    "boundWithHoldingsPerItem": [
                      {
                        "callNumber": "630.654 .I39M V.5:NO.6",
                        "instance": {
                          "title": "Absorption of lime by soils. By F.J. Warth ... and Maung Po Saw ...",
                          "hrid": "a2300812"
                        }
                      },
                      {
                        "callNumber": "630.654 .I39M V.5:NO.5",
                        "instance": {
                          "title": "The phosphate requirements of some lower Burma paddy soils, by F.J. Warth ... and Maung Po Shin ...",
                          "hrid": "a2301767"
                        }
                      },
                      {
                        "callNumber": "630.654 .I39M V.5:NO.9",
                        "instance": {
                          "title": "The retention of soluble phosphates in calcareous and non-calcareous soils, by W.H. Harrison  ... and Surendralal Das ... Agricultural Research Institute, Pusa.",
                          "hrid": "a2308798"
                        }
                      },
                      {
                        "callNumber": "630.654 .I39M V.5:NO.10",
                        "instance": {
                          "title": "Windrowing sugarcane in the Northwest Frontier Province. Part I. The effect on the economical and agricultural situation, by W. Robertson Brown ... Part II. The effect on the composition of sugarcane, by W.H. Harrison ... and P.B. Sanyal ...",
                          "hrid": "a2312336"
                        }
                      },
                      {
                        "callNumber": "630.654 .I39M V.5:NO.2",
                        "instance": {
                          "title": "'Heart damage' in baled jute, by R.S. Finlow ...",
                          "hrid": "a2279186"
                        }
                      },
                      {
                        "callNumber": "630.654 .I39M V.5:NO.4",
                        "instance": {
                          "title": "Cholam (A. sorghum) as a substitute for barley in malting operations / by B. Viswanath, T. Lakshamana Row, B.A., and P.A. Raghunathaswami Ayyangar ... Agricultural Research Insitute, Pusa.",
                          "hrid": "a2285763"
                        }
                      },
                      {
                        "callNumber": "630.654 .I39M V.5:NO.3",
                        "instance": {
                          "title": "Experiments on the improvement of the date palm sugar industry in Bengal, by Harold F. Annett ... Gosta Behrari Pal ... and Indu Bhushan Chatterjee ... Agricultural Research Institute, Pusa.",
                          "hrid": "a2237322"
                        }
                      }
                    ],
                    "notes": [
                      {
                        "note": "tf:SAL 09/23/04 batch; i:kej,8/22/2008",
                        "itemNoteType": null
                      }
                    ],
                    "effectiveLocation": {
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
                        "pageAeonSite": null,
                        "pageMediationGroupKey": null,
                        "pageServicePoints": [],
                        "scanServicePointCode": "SAL3",
                        "availabilityClass": "Offsite",
                        "searchworksTreatTemporaryLocationAsPermanentLocation": null
                      }
                    },
                    "permanentLocation": null,
                    "temporaryLocation": null,
                    "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
                    "temporaryLoanTypeId": null,
                    "holdingsRecord": {
                      "id": "08cc5111-4b66-52b3-ada5-9c7881427fac",
                      "effectiveLocation": {
                        "id": "1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2",
                        "code": "SAL3-STACKS",
                        "details": {
                          "pageAeonSite": null,
                          "pageMediationGroupKey": null,
                          "pageServicePoints": [],
                          "pagingSchedule": null,
                          "scanServicePointCode": "SAL3"
                        }
                      }
                    }
                  }
                ]
              }
            }
          }
        ],
        "instanceType": {
          "name": "unspecified"
        },
        "contributors": [
          {
            "name": "Finlow, Robert Steel, 1877-",
            "primary": true
          }
        ],
        "publication": [
          {
            "dateOfPublication": "1918",
            "place": "Calcutta London",
            "publisher": "Published for the Imperial Dept. of Agriculture in India by Thacker, Spink & Co W. Thacker & Co"
          }
        ],
        "editions": [],
        "electronicAccess": [],
        "items": []
      }
      JSON
    end

    it 'has items' do
      expect(data.items.length).to be 1 
      expect(data.items.first.barcode).to eq "36105026515499"
    end

    it 'updates the item call number to the holdings call number' do
      expect(data.items.first.callnumber).to eq "630.654 .I39M V.5:NO.2"
    end

    it 'has parent_bound_withs field' do
      expect(data.parent_bound_withs.length).to be 1
      expect(data.parent_bound_withs.first['boundWithItem']['instance']['title']).to eq "The gases of swamp rice soils ... / by W.H. Harrison ... and P.A. Subramania Aiyer ..."
    end
    
    it 'does not have child_bound_withs field' do
      expect(data.child_bound_withs.present?).to be false
    end
  end

  describe '#has child_bound_withs on single record' do 
    let(:instance_response) do
      <<~JSON
      {
        "id": "3a2f9adc-ac53-5607-b5b5-47c77f0342a4",
        "hrid": "a2969234",
        "title": "Economic mobilization.",
        "identifiers": [
          {
            "value": "41000589",
            "identifierTypeObject": {
              "name": "LCCN"
            }
          },
          {
            "value": "(Sirsi) APN3065",
            "identifierTypeObject": {
              "name": "System control number"
            }
          },
          {
            "value": "(OCoLC-M)2845541",
            "identifierTypeObject": {
              "name": "OCLC"
            }
          },
          {
            "value": "(OCoLC-I)275092808",
            "identifierTypeObject": {
              "name": "OCLC"
            }
          }
        ],
        "holdingsRecords": [
          {
            "callNumber": "336 PAM B:NO.88",
            "boundWithItem": null
          }
        ],
        "instanceType": {
          "name": "unspecified"
        },
        "contributors": [
          {
            "name": "American Council on Public Affairs",
            "primary": true
          },
          {
            "name": "Schnapper, M. B. (Morris Bartel), 1912-1999",
            "primary": false
          }
        ],
        "publication": [
          {
            "dateOfPublication": "[c1940]",
            "place": "[Washington, D. C.]",
            "publisher": "American council on public affairs"
          }
        ],
        "editions": [],
        "electronicAccess": [],
        "items": [
          {
            "id": "1ca80faf-72d8-5ea2-9d99-3c361c2641ab",
            "barcode": "36105217601884",
            "discoverySuppress": false,
            "volume": null,
            "status": {
              "name": "Available"
            },
            "dueDate": null,
            "materialType": {
              "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892",
              "name": "book"
            },
            "chronology": null,
            "enumeration": null,
            "effectiveCallNumberComponents": {
              "callNumber": "336 PAM B:NO.88"
            },
            "boundWithHoldingsPerItem": [
              {
                "callNumber": "336 PAM B:NO.94",
                "instance": {
                  "title": "Governmental auditing, New Orleans, 1946-1955. A study of the auditing practices of the government of New Orleans and selected state agencies located in the city.",
                  "hrid": "a3120887"
                }
              },
              {
                "callNumber": "336 PAM B:NO.90",
                "instance": {
                  "title": "Louisiana's financial development; a fiscal survey, by Allison R. Kolb, compiled by Leo Herbert.",
                  "hrid": "a3122315"
                }
              },
              {
                "callNumber": "336 PAM B:NO.91",
                "instance": {
                  "title": "Report.",
                  "hrid": "a3122429"
                }
              },
              {
                "callNumber": "336 PAM B:NO.95",
                "instance": {
                  "title": "Ohio- first state in the Union.",
                  "hrid": "a3122583"
                }
              },
              {
                "callNumber": "336 PAM B:NO.96",
                "instance": {
                  "title": "'...to secure its blessings'. Ohio's Auditor of State.",
                  "hrid": "a3122586"
                }
              },
              {
                "callNumber": "336 PAM B:NO.93",
                "instance": {
                  "title": "Federal grant-in-aid programs; report.",
                  "hrid": "a3123948"
                }
              },
              {
                "callNumber": "336 PAM B:NO.97",
                "instance": {
                  "title": "Statement of John J. Toomey, chairman of the Committee of Ways and Means of the House of Representatives.",
                  "hrid": "a3123975"
                }
              },
              {
                "callNumber": "336 PAM B:NO.92",
                "instance": {
                  "title": "Announcement of a National Commission on Money and Credit. Membership of Commission, Statment of scope, Selection Committee, by-laws of the Commission, initial announcement.",
                  "hrid": "a3124555"
                }
              }
            ],
            "notes": [
              {
                "note": "tf:SAL 06/12/13 batch; c:mks / i:vtd 6/4/13/  bw no.90-97; Class Code corrected 5/3/95 skt",
                "itemNoteType": null
              }
            ],
            "effectiveLocation": {
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
                "pageAeonSite": null,
                "pageMediationGroupKey": null,
                "pageServicePoints": [],
                "scanServicePointCode": "SAL3",
                "availabilityClass": "Offsite",
                "searchworksTreatTemporaryLocationAsPermanentLocation": null
              }
            },
            "permanentLocation": null,
            "temporaryLocation": null,
            "permanentLoanTypeId": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "temporaryLoanTypeId": null,
            "holdingsRecord": {
              "id": "ff4fa9ce-235a-5329-85f2-faeea2e9ebff",
              "effectiveLocation": {
                "id": "1146c4fa-5798-40e1-9b8e-92ee4c9f2ee2",
                "code": "SAL3-STACKS",
                "details": {
                  "pageAeonSite": null,
                  "pageMediationGroupKey": null,
                  "pageServicePoints": [],
                  "pagingSchedule": null,
                  "scanServicePointCode": "SAL3"
                }
              }
            }
          }
        ]
      }
      JSON
    end

    it 'has items' do
      expect(data.items.length).to be 1 
      expect(data.items.first.barcode).to eq "36105217601884"
    end

    it 'does not update the item call number' do
      expect(data.items.first.callnumber).to eq "336 PAM B:NO.88"
    end

    it 'does not have parent_bound_withs field' do
      expect(data.parent_bound_withs.length).to be 0
    end
    
    it 'has child_bound_withs field' do
      expect(data.child_bound_withs.length).to be 8
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
