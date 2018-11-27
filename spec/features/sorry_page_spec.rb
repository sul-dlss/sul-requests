# frozen_string_literal: true

require 'rails_helper'

describe 'Viewing sorry page' do
  it 'displays some text' do
    visit sorry_unable_path
    expect(page).to have_css('p', text: 'greencirc@stanford.edu')
    expect(page).to have_css('p', text: '(650) 723-1493')
  end
end
