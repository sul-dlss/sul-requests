require 'rails_helper'

describe 'Viewing sorry page' do
  it 'should display some text' do
    visit sorry_unable_path
    expect(page).to have_css('p', 'greencirc@stanford.edu')
    expect(page).to have_css('p', '(650) 723-1493')
  end
end
