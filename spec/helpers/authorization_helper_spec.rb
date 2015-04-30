require 'rails_helper'

describe AuthorizationHelper do
  describe '#mediated_locations_for' do
    it 'should check if the current use can manage each of the provided locations' do
      expect(helper).to receive(:can?).exactly(:twice).with(:manage, an_instance_of(LibraryLocation))
      helper.mediated_locations_for(['SAL3', 'SPEC-COLL'])
    end
  end
end
