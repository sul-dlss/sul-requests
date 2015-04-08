require 'rails_helper'

describe 'home/show' do
  before do
    render
  end
  it 'should have title and description' do
    expect(rendered).to have_css('h2', text: 'Mediation')
    expect(rendered).to have_css('a', text: 'Special Collections')
    expect(rendered).to have_css('a', text: 'Hoover Library')
    expect(rendered).to have_css('a', text: 'Hoover Archives')
    expect(rendered).to have_css('a', text: 'Earth Sciences Library (Branner)')
    expect(rendered).to have_css('a', text: 'Marine Biology Library (Miller)')
  end
end
