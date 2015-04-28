RSpec.configure do |config|
  # Include factory_girl syntax
  config.include FactoryGirl::Syntax::Methods

  # Run factory_girl linter to validate all fixtures
  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end
