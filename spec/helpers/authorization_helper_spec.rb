# frozen_string_literal: true

require 'rails_helper'

describe AuthorizationHelper do
  describe '#mediated_locations_for' do
    it 'checks if the current use can manage each of the provided locations' do
      expect(helper).to receive(:can?).exactly(:twice).with(:manage, an_instance_of(LibraryLocation))
      helper.mediated_locations_for('SAL3' => double(library_override: false), 'SPEC-COLL' => double(library_override: false))
    end
  end
end
