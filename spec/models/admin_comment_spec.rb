# frozen_string_literal: true

require 'rails_helper'

describe AdminComment do
  describe 'validations' do
    it 'a comment is required' do
      expect { AdminComment.create!(commenter: 'user') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'a commenter is required' do
      expect { AdminComment.create!(comment: 'The Comment') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'is successful when a comment and a commenter are provided' do
      expect(AdminComment.create!(comment: 'The Comment', commenter: 'user')).to be_a AdminComment
    end
  end
end
