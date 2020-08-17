# frozen_string_literal: true

require 'rails_helper'

describe 'Eligibility Validation' do
  let(:user) { create(:webauth_user) }

  before do
    expect(Settings.features).to receive(:validate_eligibility).and_return(true)
    stub_current_user(user)
  end

  context 'for page requests' do
    context 'when the user making the request has an eligible affiliation' do
      before do
        user.affiliation = 'stanford:student'
      end

      it 'allows the request to be submitted' do
        visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
        first(:button, 'Send request').click

        expect(current_url).to eq successful_page_url(Page.last)
        expect_to_be_on_success_page
      end
    end

    context 'when the user making the request does not have an eligible affiliation' do
      before do
        user.affiliation = 'stanford:affiliate:sponsored'
      end

      it 'sends the user to the ineligible pages page' do
        visit new_page_path(item_id: '1234', origin: 'GREEN', origin_location: 'STACKS')
        first(:button, 'Send request').click

        expect(current_url).to eq ineligible_pages_url(origin: 'GREEN')
        expect(page).to have_css('h1#dialogTitle', text: /Sorry, we can't fulfill your request/)
        expect(Page.last).to be_nil
      end
    end
  end

  context 'for mediated page requests ' do
    context 'when the user has an eligibible affiliation' do
      before do
        user.affiliation = 'stanford:faculty'
      end

      it 'allows the request to be submitted' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
        first(:button, 'Send request').click

        expect(current_url).to eq successful_mediated_page_url(MediatedPage.last)
        expect_to_be_on_success_page
      end
    end

    context 'when the user has a student affiliation but has a type of "graduate"' do
      before do
        user.affiliation = 'stanford:student'
        user.student_type = 'graduate'
      end

      it 'allows the request to be submitted' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
        first(:button, 'Send request').click

        expect(current_url).to eq successful_mediated_page_url(MediatedPage.last)
        expect_to_be_on_success_page
      end
    end

    context 'when the user has an ineligible affiliation' do
      before do
        user.affiliation = 'stanford:faculty:nonactive'
      end

      it 'sends the user to the ineligible mediated pages page' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
        first(:button, 'Send request').click

        expect(current_url).to eq ineligible_mediated_pages_url(origin: 'SPEC-COLL')
        expect(page).to have_css('h1#dialogTitle', text: /Sorry, we can't fulfill your request/)
        expect(MediatedPage.last).to be_nil
      end
    end

    context 'when the user as an ineligible affiliation but can manage the request' do
      before do
        expect(Settings).to receive(:origin_admin_groups).and_return(
          'SPEC-COLL' => ['sul:spec-coll-test-admins']
        )
        user.affiliation = 'stanford:staff'
        user.ldap_group_string = 'sul:spec-coll-test-admins'
      end

      it 'allows users who can manage the mediated page to submit the request ' do
        visit new_mediated_page_path(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS')
        first(:button, 'Send request').click

        expect(current_url).to eq successful_mediated_page_url(MediatedPage.last)
        expect_to_be_on_success_page
      end
    end
  end
end
