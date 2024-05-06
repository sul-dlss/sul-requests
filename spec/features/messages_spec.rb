# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing all requests' do
  describe 'index' do
    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
      end

      it 'lists data in tables' do
        visit messages_path
        expect(page).to have_css('h1', text: 'Broadcast messages for request forms')
        expect(page).to have_css('h2', text: /Page from anywhere/)
        expect(page).to have_css('h2', text: /Page from SAL1&2/)
        expect(page).to have_css('h2', text: /Page from SAL3/)
        expect(page).to have_css('h2', text: /Page from SAL Newark/)
      end
    end

    describe 'by an anonmyous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'is forbidden' do
        visit messages_path
        expect(page.status_code).to eq 403
      end
    end
  end

  describe 'create' do
    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
      end

      it 'lists data in tables' do
        visit new_message_path(library: 'SAL3', request_type: 'page')

        expect(page).to have_css('h1', text: /Page from SAL3/)

        fill_in 'Text', with: 'This is an important message'
        fill_in 'Display from', with: '01/01/2000'
        fill_in 'through', with: '01/01/2100'

        click_on 'Save'

        within '.library-page-SAL3' do
          expect(page).to have_content 'This is an important message'
          expect(page).to have_content 'Active Jan 1, 2000 through Jan 1, 2100'
        end
      end
    end

    describe 'by an anonmyous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'is forbidden' do
        visit new_message_path
        expect(page.status_code).to eq 403
      end
    end
  end

  describe 'update' do
    let(:message) { create(:message, library: 'SAL3') }

    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
      end

      it 'lists data in tables' do
        visit edit_message_path(message)

        expect(page).to have_css('h1', text: /Page from SAL3/)

        expect(page).to have_css('textarea', text: 'MyText')

        fill_in 'Text', with: 'This is an important message'
        fill_in 'Display from', with: '01/01/2000'
        fill_in 'through', with: '01/01/2100'

        click_on 'Save'

        within '.library-page-SAL3' do
          expect(page).to have_content 'This is an important message'
          expect(page).to have_content 'Active Jan 1, 2000 through Jan 1, 2100'
        end
      end
    end

    describe 'by an anonmyous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'is forbidden' do
        visit edit_message_path(message)
        expect(page.status_code).to eq 403
      end
    end
  end

  describe 'destroy' do
    before do
      create(:message, library: 'SAL3')
    end

    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
      end

      it 'messages can be destroyed' do
        visit messages_path

        expect(Message.count).to be 1
        expect(page).to have_css('.text.alert', text: 'MyText')
        click_on 'Delete message'
        expect(page).to have_no_css('.text.alert', text: 'MyText')
        expect(Message.count).to be_zero
      end
    end
  end

  describe 'displays on a request page' do
    let(:message) { create(:message) }

    before do
      stub_bib_data_json(build(:single_mediated_holding))
    end

    it 'displays the broadcast message' do
      visit new_request_path(item_id: '1234', origin: message.library, origin_location: 'ART-LOCKED-LARGE')
      expect(page).to have_content message.text
    end
  end
end
