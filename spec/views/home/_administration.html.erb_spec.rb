require 'rails_helper'

describe 'home/_administration.html.erb' do
  before do
    render
  end
  it 'should have title and description' do
    expect(rendered).to have_css('h2', text: 'Administration')
    expect(rendered).to have_css('a', text: 'Broadcast messages')
    expect(rendered).to have_css('a', text: 'Paging schedule')
  end
end
