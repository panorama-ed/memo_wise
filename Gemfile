# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :test do
  if RUBY_VERSION.start_with?("2.7")
    # Match only Ruby version we run the linters on in CI
    gem "panolint", github: "panorama-ed/panolint"
  end
  gem "rspec", "~> 3.0"
  gem "values", "~> 1"
end
