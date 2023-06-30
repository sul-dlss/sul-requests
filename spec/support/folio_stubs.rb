# frozen_string_literal: true

def stub_folio_holdings(fixture_name)
  if fixture_name == :empty
    holdings_relationship = double(:relationship, where: [], all: [], single_checked_out_item?: false)
    allow(HoldingsRelationshipBuilder).to receive(:build).and_return(holdings_relationship)
  else
    allow_any_instance_of(FolioClient).to receive(:items_and_holdings).and_return(StubFolioApiResponse.send(fixture_name))
  end
end

class StubFolioApiResponse
  # rubocop:disable Metrics/MethodLength
  def self.folio_multiple_holding
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
      [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
         'notes' => [],
         'status' => 'Available',
         'barcode' => '3610512345678',
         'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
         'callNumber' =>
            { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 123' },
         'materialType' => 'periodical',
         'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
         'permanentLoanType' => 'Can circulate',
         'suppressFromDiscovery' => false },
       { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
         'notes' => [],
         'status' => 'Available',
         'barcode' => '3610587654321',
         'location' =>
         { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
           'permanentLocation' => { 'code' => 'GRE-STACKS' },
           'temporaryLocation' => {} },
         'callNumber' =>
           { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 321' },
         'materialType' => 'periodical',
         'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
         'permanentLoanType' => 'Can circulate',
         'suppressFromDiscovery' => false },
       { 'id' => 'deec4ae9-545c-5d60-85b0-b1048b9dad05',
         'notes' => [],
         'status' => 'Available',
         'barcode' => '12345679',
         'location' =>
         { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
           'permanentLocation' => { 'code' => 'GRE-STACKS' },
           'temporaryLocation' => {} },
         'callNumber' => { 'callNumber' => 'ABC 456' },
         'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
         'materialType' => 'book',
         'permanentLoanType' => 'Can circulate',
         'suppressFromDiscovery' => false }] }
  end

  def self.folio_sal3_multiple_holdings
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
      [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
         'notes' => [],
         'status' => 'Available',
         'barcode' => '12345678',
         'location' =>
          { 'effectiveLocation' => { 'code' => 'SAL3-STACKS' },
            'permanentLocation' => { 'code' => 'SAL3-STACKS' },
            'temporaryLocation' => {} },
         'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
         'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
         'materialType' => 'book',
         'permanentLoanType' => 'Can circulate',
         'suppressFromDiscovery' => false },
       { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
         'notes' => [],
         'status' => 'Available',
         'barcode' => '87654321',
         'location' =>
         { 'effectiveLocation' => { 'code' => 'SAL3-STACKS' },
           'permanentLocation' => { 'code' => 'SAL3-STACKS' },
           'temporaryLocation' => {} },
         'callNumber' => { 'callNumber' => 'PR6123 .E475 W42 2009' },
         'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
         'materialType' => 'book',
         'permanentLoanType' => 'Can circulate',
         'suppressFromDiscovery' => false }] }
  end

  def self.folio_single_holding
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
      [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
         'notes' => [],
         'status' => 'Available',
         'barcode' => '3610512345678',
         'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
         'callNumber' =>
            { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 123' },
         'materialType' => 'periodical',
         'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
         'permanentLoanType' => 'Can circulate',
         'suppressFromDiscovery' => false }] }
  end
  # rubocop:enable Metrics/MethodLength
end
