# frozen_string_literal: true

require 'rails_helper'

feature 'Home Page' do
  describe 'layout' do
    before do
      visit root_path
    end
    it 'should have the application name as the page title' do
      expect(page).to have_title('SUL Requests')
    end
    it 'should display logo' do
      expect(page).to have_css('header.header-logo')
    end
    it 'should display top menu links' do
      expect(page).to have_css('.header-links a', text: 'My Account')
      expect(page).to have_css('.header-links a', text: 'Feedback')
    end

    it 'should have a target="_blank" feedback link (with appropriate rel attribute)' do
      feedback_link = page.find('.header-links a', text: 'Feedback')
      expect(feedback_link['target']).to eq '_blank'
      expect(feedback_link['rel']).to eq 'noopener noreferrer'
    end

    it 'should display SUL footer' do
      expect(page).to have_css('#sul-footer #sul-footer-img img')
      expect(page).to have_css('#sul-footer-links a', text: 'Stanford University Libraries')
      expect(page).to have_css('#sul-footer-links a', text: 'Hours & locations')
      expect(page).to have_css('#sul-footer-links a', text: 'My Account')
      expect(page).to have_css('#sul-footer-links a', text: 'Ask us')
      expect(page).to have_css('#sul-footer-links a', text: 'Opt out of analytics')
    end
    it 'should display SU footer' do
      expect(page).to have_css('#global-footer #bottom-logo img')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'SU Home')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Maps & Directions')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Search Stanford')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Terms of Use')
      expect(page).to have_css('#global-footer #bottom-text a', text: 'Emergency Info')
    end
  end

  describe 'mediation section' do
    before do
      create(:mediated_page)
      create(:page_mp_mediated_page)
      stub_current_user(create(:superadmin_user))
      visit root_path
    end

    it 'has links for the library level mediation' do
      expect(page).to have_link('Special Collections', href: '/admin/SPEC-COLL')
    end

    it 'has links for the location level mediation' do
      expect(page).to have_link('Earth Sciences Library (Branner)', href: '/admin/PAGE-MP')
    end
  end
end
