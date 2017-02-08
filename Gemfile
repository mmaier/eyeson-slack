source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.1', '>= 5.0.0.1'
# Use Puma as the app server
gem 'puma', '~> 3.0'

gem 'unicorn'
gem 'syslog-logger'
gem 'slack-ruby-client'
gem 'oauth2'
gem 'mongoid', '~> 6.0.0'

gem 'eyeson', git: 'ssh://git@gitlab.infra.dev-visocon.com:2222/mmaier/eyeson-gem.git'

group :development, :test do
  # Use ruby community standard and best practices
  gem 'rubocop', require: false
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :test do
  # Use factories over fixtures
  gem 'factory_girl_rails'
  # Use random test data over static
  gem 'faker'
  # Use rspec over minitests
  gem 'rspec-rails', '~> 3.5'
  # Use mongoid-rspec and shoulda matcher test helper
  gem 'mongoid-rspec', git: 'https://github.com/phinfonet/mongoid-rspec'
  gem 'shoulda-matchers', '~> 3.1'
  # Fake oauth requests
  gem 'mocha'
  # Generate test coverage report
  gem 'simplecov', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
