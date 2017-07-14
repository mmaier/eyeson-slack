source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.1', '>= 5.0.0.1'
# Use Puma as the app server
gem 'puma', '~> 3.0'

gem 'mongoid', '~> 6.0.0'
gem 'oauth2'
gem 'rest-client'
gem 'slack-ruby-client'
gem 'syslog-logger'
gem 'unicorn'
gem 'delayed_job_mongoid'

gem 'eyeson', git: 'https://gitlab.infra.dev-visocon.com/eyeson/eyeson-ruby.git', :tag => 'v2.3.1'

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
  gem 'listen', '~> 3.0.5'
  gem 'web-console'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
gem 'daemons'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i(mingw mswin x64_mingw jruby)
