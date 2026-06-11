# frozen_string_literal: true

# test helpers for setting up tests to use the stub aeon server
module AeonStubHelpers
  def use_stub_aeon_client
    before do
      Settings.aeon.api_url = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/stub_aeon_client/"
    end
  end
end

RSpec.configure do |config|
  config.extend AeonStubHelpers, type: :feature
end
