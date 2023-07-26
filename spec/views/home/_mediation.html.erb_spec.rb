# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'home/_mediation.html.erb' do
  before do
    allow(view).to receive_messages(
      locations: ['SPEC-COLL']
    )
    render
  end

  it 'has title and description' do
    expect(rendered).to have_css('h2', text: 'Mediation')
    expect(rendered).to have_css('a', text: 'Special Collections')
  end
end
