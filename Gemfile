# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :test do
  gem "rspec", "~> 3.13"
  gem "values", "~> 1"
end

# Excluded from CI except on latest MRI Ruby, to reduce compatibility burden
group :checks, optional: true do
  gem "panolint-ruby", github: "panorama-ed/panolint-ruby", branch: "main"

  # Simplecov to generate coverage info
  gem "simplecov", require: false

  # Simplecov-cobertura to generate an xml coverage file to upload to Codecov
  gem "simplecov-cobertura", require: false
end

# Excluded from CI except on latest MRI Ruby, to reduce compatibility burden
group :docs, optional: true do
  gem "redcarpet", "~> 3.6"
  gem "webrick", "~> 1.8"
  gem "yard", "~> 0.9"
  gem "yard-doctest", "~> 0.1"
end

# Excluded from CI except on the latest Ruby version that supports dokaz
group :dokaz, optional: true do
  gem "dokaz", "~> 0.0.5"
end

# Optional, only used locally to release to rubygems.org
group :release, optional: true do
  gem "rake"
end
