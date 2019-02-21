# frozen_string_literal: true

RSpec.configure do |config|
  # Include factory_bot syntax
  config.include FactoryBot::Syntax::Methods

  # Run factory_bot linter to validate all fixtures
  config.before(:suite) do
    DatabaseCleaner.start
    factories_to_lint = FactoryBot.factories.reject do |factory|
      # Remove _holdings and _searchworks_item since they are not active record objects
      factory.name =~ /_holdings?$/ || factory.name =~ /_searchworks_item$/ || factory.name =~ /^symphony_/
    end

    FactoryBot.lint factories_to_lint unless config.files_to_run.one?
  ensure
    DatabaseCleaner.clean
  end
end
