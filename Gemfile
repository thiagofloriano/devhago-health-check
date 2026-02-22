source 'https://rubygems.org'

# Gem dependencies
gemspec

# Test dependencies
group :test do
  gem 'minitest', '~> 5.0'
  gem 'minitest-reporters', '~> 1.5'
  gem 'webmock', '~> 3.18'
  gem 'sqlite3', '~> 2.1' # Match Rails 8 requirement
end

group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'pry', '~> 0.14'
end
