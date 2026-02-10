# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestComponent, type: :component do
  let(:request) { build(:aeon_request) }

  before do
    render_inline(described_class.new(request:))
  end

  it 'renders' do
    expect(page).to have_text('Throwing a sinker ball at 94 mpg with wicked movement')
    expect(page).to have_link 'View in SearchWorks', href: 'https://searchworks.stanford.edu/view/12345678'
    expect(page).to have_text('Mar 11, 2024')
    expect(page).to have_text('1 pm - 1:15 pm (PDT)')
    expect(page).to have_text('Field Reading Room')
  end
end
