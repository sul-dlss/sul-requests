# frozen_string_literal: true

require 'rails_helper'

describe 'AdminComments' do
  let(:user) { create(:superadmin_user) }
  let(:mediated_page) { create(:mediated_page) }
  let(:headers) { { 'HTTP_REFERER' => 'http://example.com' } }
  let(:url) { "/mediated_pages/#{mediated_page.id}/admin_comments" }

  before do
    stub_current_user(user)
  end

  describe '#create' do
    context 'when successful' do
      it "merges the current user's webauth into the persisted comment as the commenter" do
        post(url, { admin_comment: { comment: 'This is a comment' } }, headers)
        expect(AdminComment.last.commenter).to eq user.webauth
      end

      context 'html response' do
        it 'redirects back with a flash notice' do
          post(url, { admin_comment: { comment: 'This is another comment' } }, headers)
          expect(response).to redirect_to(:back)
          expect(flash[:notice]).to eq 'Comment was successfully created.'
          expect(AdminComment.last.comment).to eq 'This is another comment'
        end
      end

      context 'js response' do
        it 'returns a succesful status code' do
          post("#{url}.js", { admin_comment: { comment: 'This is yet another comment' } }, headers)
          expect(response).to be_success
        end
        it 'returns the JSON of the comment object that was just created' do
          post("#{url}.js", { admin_comment: { comment: 'This is yet another comment' } }, headers)
          response_comment = JSON.parse(response.body)
          last_comment = AdminComment.last
          expect(response_comment['id']).to eq last_comment.id
          expect(response_comment['comment']).to eq last_comment.comment
          expect(response_comment['commenter']).to eq last_comment.commenter
        end
      end
    end

    context 'when unsuccessful' do
      before { expect_any_instance_of(AdminComment).to receive(:save).and_return(false) }

      context 'html response' do
        it 'redirects back with a flash error' do
          post(url, { admin_comment: { comment: 'A comment that will not be persisted' } }, headers)
          expect(response).to redirect_to(:back)
          expect(flash[:error]).to eq 'There was an error creating your comment.'
        end
      end

      context 'js response' do
        it 'returns a failure status code' do
          post("#{url}.js", { admin_comment: { comment: 'A comment that will not be persisted' } }, headers)
          expect(response).not_to be_success
          expect(JSON.parse(response.body)).to eq('status' => 'error')
        end
      end
    end
  end

  context 'by a user who cannot add admin comments' do
    let(:user) { create(:webauth_user) }

    it 'raises an access denied error' do
      expect { post(url, admin_comment: { comment: 'A comment' }) }.to raise_error(CanCan::AccessDenied)
    end
  end
end
