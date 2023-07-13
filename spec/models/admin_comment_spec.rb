# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminComment do
  describe 'validations' do
    it 'a comment is required' do
      expect { described_class.create!(commenter: 'user') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'a commenter is required' do
      expect { described_class.create!(comment: 'The Comment') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'is successful when a comment and a commenter are provided' do
      expect(described_class.create!(comment: 'The Comment', commenter: 'user')).to be_a described_class
    end
  end
end
