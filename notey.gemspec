# frozen_string_literal: true

require_relative "lib/notey/version"

Gem::Specification.new do |spec|
  spec.name = "notey"
  spec.version = Notey::VERSION
  spec.authors = [ "tylercschneider" ]
  spec.email = [ "tylercschneider@gmail.com" ]

  spec.summary = "Notification preferences, in-app inbox and digests over Noticed"
  spec.description = "Notey is the notification layer for multi-tenant apps. Noticed delivers a " \
    "notification on whatever channels a notifier declares; Notey stores which channels each person " \
    "wants per notification type, gives them screens to set that, scopes an inbox to the account they " \
    "are in, and groups notifications into digests instead of sending each one as it happens."
  spec.homepage = "https://github.com/DYB-Development/notey"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "noticed", ">= 3.0"
  spec.add_dependency "keystone_ui", ">= 0.9"
end
