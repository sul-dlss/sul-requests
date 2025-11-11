# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'home/_administration.html.erb' do
  before do
    render
  end

  it 'has title and description' do
    expect(rendered).to have_css('h2', text: 'Administration')
  end

  it 'has expected links' do
    expect(rendered).to have_css('a', text: 'Requests job queue')
    expect(rendered).to have_css('a', text: 'Broadcast messages')
    expect(rendered).to have_css('a', text: 'Paging schedule')
  end
end
