# frozen_string_literal: true

require 'rails_helper'

describe Custom do
  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Custom'
  end
end
