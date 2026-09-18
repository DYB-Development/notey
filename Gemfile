source "https://rubygems.org"

# Specify your gem's dependencies in notey.gemspec.
gemspec

gem "the_local", github: "DYB-Development/the_local"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

group :development, :test do
  gem "puma"
  gem "sqlite3"
  gem "propshaft"
  gem "pry"
  gem "minitest", "~> 5.0"

  gem "json", "< 3"

  gem "event_engine-subscribers", ">= 0.1"
end
