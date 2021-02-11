# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :test do
  gem "rspec", "~> 3.10"
  gem "values", "~> 1"
end

# Excluded from CI except on latest MRI Ruby, to reduce compatibility burden
group :checks do
  gem "codecov"
  gem "panolint", github: "panorama-ed/panolint"
end

# Excluded from CI except on latest MRI Ruby, to reduce compatibility burden
group :docs do
  gem "redcarpet", "~> 3.5"
  gem "yard", "~> 0.9"
  gem "yard-doctest", "~> 0.1"
end

# Optional, only used locally to release to rubygems.org
group :release, optional: true do
  gem "rake"
end
