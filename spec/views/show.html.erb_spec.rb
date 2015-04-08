require 'rails_helper'

describe 'home/show' do
  before do
    render
  end
  it 'should have title and links' do
    expect(rendered).to have_css('h1', text: 'Request management')
    expect(rendered).to have_css('h4', text: /^Administration and mediation tasks for page/)
  end
end
