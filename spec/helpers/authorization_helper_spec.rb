# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationHelper do
  describe '#mediated_locations_for' do
    let(:locations) do
      {
        'SAL3' => double(library_override: false),
        'SPEC-COLL' => double(library_override: false),
        'PAGE-MP' => double(library_override: 'EARTH-SCI')
      }
    end

    before do
      allow(controller).to receive(:current_ability).and_return(Ability.new(user))
    end

    context 'with a super user' do
      let(:user) { build(:superadmin_user) }

      it 'returns all the provided locations' do
        expect(helper.mediated_locations_for(locations)).to include('SAL3', 'SPEC-COLL', 'PAGE-MP')
      end
    end

    context 'with an origin location admin' do
      let(:user) { build(:page_mp_origin_admin_user) }

      it 'return just the origin location the user is authorized for' do
        expect(helper.mediated_locations_for(locations)).to include('PAGE-MP')
      end
    end
  end
end
