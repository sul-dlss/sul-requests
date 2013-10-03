source 'https://rubygems.org'
source 'http://sul-gems.stanford.edu'

gem 'rails', '3.2.14'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# From Rails 2 Gemfile
gem "builder"
gem "bundler"
gem "marc"
gem "mysql"
gem "nokogiri"
gem "rack"
gem "rake"
gem "request-log-analyzer"

group :test do
   gem "cucumber"
   gem "cucumber-rails", :require => false
   gem "test-unit"   # seems to be referenced in rspec task file
   gem "gherkin"
   gem "rdoc"
   gem "simplecov", :require => false
   gem "rspec"
   gem "rspec-rails"
   gem "webrat"
end

group :development, :test do 
  gem 'rspec-rails' 
  gem 'factory_girl_rails' 
end 
  
group :test do 
  gem 'faker' 
  gem 'capybara' 
  gem 'guard-rspec' 
  gem 'launchy' 
end 


# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
group :deployment do
  gem 'lyberteam-capistrano-devel'
  gem 'net-ssh-krb'
  gem 'gssapi', :github => 'cbeer/gssapi'
end



# To use debugger
# gem 'debugger'
