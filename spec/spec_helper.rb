# frozen_string_literal: true

# Simplecov needs to be loaded before we require `memo_wise` in order to
# properly track all memo_wise files
if Gem.loaded_specs.key?("codecov")
  require "codecov"
  require "simplecov"

  SimpleCov.start do
    enable_coverage :branch
  end

  SimpleCov.formatter = if ENV["CI"] == "true"
                          SimpleCov::Formatter::Codecov
                        else
                          # Writes coverage file into coverage/index.html
                          # when run outside of CI for local development
                          SimpleCov::Formatter::HTMLFormatter
                        end

  # SimpleCov.refuse_coverage_drop is only implemented for line coverage, so for
  # branch coverage we must use `minimum_coverage`
  SimpleCov.minimum_coverage branch: 100

  SimpleCov.refuse_coverage_drop
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require "bundler/setup"

# The gem that we are testing! :)
require "memo_wise"

# Support code for tests
require "support/define_methods_for_testing_memo_wise"
