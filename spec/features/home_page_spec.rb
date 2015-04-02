require "rails_helper"

describe 'Home Page' do
  it 'should have the application name as the page title' do
    visit '/'
    expect(page).to have_title("SUL Requests")
  end
end
