# frozen_string_literal: true

require 'rails_helper'

describe 'home/_mediation.html.erb' do
  before do
    allow(view).to receive_messages(
      locations: ['SPEC-COLL', 'HOOVER', 'HV-ARCHIVE']
    )
    render
  end
  it 'should have title and description' do
    expect(rendered).to have_css('h2', text: 'Mediation')
    expect(rendered).to have_css('a', text: 'Special Collections')
    expect(rendered).to have_css('a', text: 'Hoover Library')
    expect(rendered).to have_css('a', text: 'Hoover Archives')
  end
end
