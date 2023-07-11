# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'home/_mediation.html.erb' do
  before do
    allow(view).to receive_messages(
      locations: ['SPEC-COLL', 'HOOVER', 'HV-ARCHIVE']
    )
    render
  end

  it 'has title and description' do
    expect(rendered).to have_css('h2', text: 'Mediation')
    expect(rendered).to have_css('a', text: 'Special Collections')
    expect(rendered).to have_css('a', text: 'Hoover Library')
    expect(rendered).to have_css('a', text: 'Hoover Archives')
  end
end
