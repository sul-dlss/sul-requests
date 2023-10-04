# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminComments' do
  let(:user) { create(:superadmin_user) }
  let(:mediated_page) { create(:mediated_page_with_holdings) }
  let(:headers) { { 'HTTP_REFERER' => 'http://example.com' } }
  let(:url) { "/mediated_pages/#{mediated_page.id}/admin_comments" }

  before do
    stub_current_user(user)
  end

  describe '#create' do
    context 'when successful' do
      it "merges the current user's sunetid into the persisted comment as the commenter" do
        post(url, params: { admin_comment: { comment: 'This is a comment' } }, headers:)
        expect(AdminComment.last.commenter).to eq user.sunetid
      end

      context 'html response' do
        it 'redirects back with a flash notice' do
          post(url, params: { admin_comment: { comment: 'This is another comment' } }, headers:)
          expect(flash[:notice]).to eq 'Comment was successfully created.'
          expect(AdminComment.last.comment).to eq 'This is another comment'
        end
      end
    end

    context 'when unsuccessful' do
      before { expect_any_instance_of(AdminComment).to receive(:save).and_return(false) }

      context 'html response' do
        it 'redirects back with a flash error' do
          post(url, params: { admin_comment: { comment: 'A comment that will not be persisted' } }, headers:)
          expect(flash[:error]).to eq 'There was an error creating your comment.'
        end
      end
    end
  end

  context 'by a user who cannot add admin comments' do
    let(:user) { create(:sso_user) }

    it 'is forbidden' do
      post(url, params: { admin_comment: { comment: 'A comment' } })
      expect(response).to have_http_status(:forbidden)
    end
  end
end
