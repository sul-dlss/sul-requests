RSpec.configure do |config|
  # Include factory_girl syntax
  config.include FactoryGirl::Syntax::Methods

  # Run factory_girl linter to validate all fixtures
  config.before(:suite) do
    begin
      DatabaseCleaner.start
      factories_to_lint = FactoryGirl.factories.reject do |factory|
        # Remove _holdings and _searchworks_item since they are not active record objects
        factory.name =~ /_holdings?$/ || factory.name =~ /_searchworks_item$/ || factory.name =~ /^symphony_/
      end
      FactoryGirl.lint factories_to_lint
    ensure
      DatabaseCleaner.clean
    end
  end
end
