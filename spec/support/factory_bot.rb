# frozen_string_literal: true

RSpec.configure do |config|
  # Include factory_bot syntax
  config.include FactoryBot::Syntax::Methods

  # Run factory_bot linter to validate all fixtures
  config.before(:suite) do
    DatabaseCleaner.start
    factories_to_lint = FactoryBot.factories.reject do |factory|
      factory.name == :scan || # Produces an invalid object (no matching holdings)
        [Hash, SearchworksItem].include?(factory.build_class)  # non-activerecord objects (Hashes)
    end

    FactoryBot.lint factories_to_lint unless config.files_to_run.one?
  ensure
    DatabaseCleaner.clean
  end
end
