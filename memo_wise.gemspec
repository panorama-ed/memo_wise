# frozen_string_literal: true

require_relative "lib/memo_wise/version"

Gem::Specification.new do |spec|
  spec.name     = "memo_wise"
  spec.version  = MemoWise::VERSION
  spec.summary  = "The wise choice for Ruby memoization"
  spec.homepage = "https://github.com/panorama-ed/memo_wise"
  spec.license  = "MIT"

  spec.authors = [
    "Panorama Education",
    "Jacob Evelyn",
    "Jemma Issroff",
    "Marc Siegel",
  ]

  spec.email = [
    "engineering@panoramaed.com",
    "jacobevelyn@gmail.com",
    "jemmaissroff@gmail.com",
    "marc@usainnov.com",
  ]

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{CHANGELOG.md,LICENSE.txt,README.md,lib/**/*.rb}")
  spec.require_paths = ["lib"]

  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "changelog_uri" => "https://github.com/panorama-ed/memo_wise/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/panorama-ed/memo_wise"
  }
end
