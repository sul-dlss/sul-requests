require 'rails_helper'

describe 'Viewing all requests' do
  describe 'index' do
    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
      end
      it 'should list data in tables' do
        visit messages_path

        expect(page).to have_css('h1', text: 'Broadcast messages for request forms')
        expect(page).to have_css('h2', text: /Page from anywhere/)
        expect(page).to have_css('h2', text: /Page from Archive of Recorded Sound/)
        expect(page).to have_css('h2', text: /Page from Green Library/)
      end
    end

    describe 'by an anonmyous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'should raise an error' do
        expect(
          -> { visit messages_path }
        ).to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'create' do
    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
      end
      it 'should list data in tables' do
        visit new_message_path(library: 'ARS', request_type: 'page')

        expect(page).to have_css('h1', text: /Page from Archive of Recorded Sound/)

        fill_in 'Text', with: 'This is an important message'
        fill_in 'Display from', with: '01/01/2000'
        fill_in 'through', with: '01/01/2100'

        click_on 'Save'

        within '.library-page-ARS' do
          expect(page).to have_content 'This is an important message'
          expect(page).to have_content 'Active 2000-01-01 through 2100-01-01'
        end
      end
    end

    describe 'by an anonmyous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'should raise an error' do
        expect(
          -> { visit new_message_path }
        ).to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'update' do
    let(:message) { create(:message) }

    describe 'by a superadmin user' do
      before do
        stub_current_user(create(:superadmin_user))
      end

      it 'should list data in tables' do
        visit edit_message_path(message)

        expect(page).to have_css('h1', text: /Page from Special Collections/)

        expect(page).to have_css('textarea', text: 'MyText')

        fill_in 'Text', with: 'This is an important message'
        fill_in 'Display from', with: '01/01/2000'
        fill_in 'through', with: '01/01/2100'

        click_on 'Save'

        within '.library-page-SPEC-COLL' do
          expect(page).to have_content 'This is an important message'
          expect(page).to have_content 'Active 2000-01-01 through 2100-01-01'
        end
      end
    end

    describe 'by an anonmyous user' do
      before { stub_current_user(create(:anon_user)) }

      it 'should raise an error' do
        expect(
          -> { visit edit_message_path(message) }
        ).to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'displays on a request page' do
    let(:message) { create(:message) }

    it 'should display the broadcast message' do
      visit new_mediated_page_path(item_id: '1234', origin: message.library, origin_location: 'STACKS')
      expect(page).to have_content message.text
    end
  end
end
