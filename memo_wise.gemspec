# frozen_string_literal: true

# After loading the `VERSION` constant, save it to a variable to use in this
# gemspec and then undefine it. This allows benchmarks to compare multiple
# versions of MemoWise against each other without inadvertently sharing the same
# `VERSION` constant.
# NOTE: It's important that we use `load` instead of `require_relative` because
# the latter only loads a file once, and so by undefining the `VERSION` constant
# we can make it difficult to access that value again later. For more context,
# see: https://github.com/panorama-ed/memo_wise/pull/370#issuecomment-2560268423
# NOTE: If we ever bump the minimum Ruby version to 3.1+, we can simplify this
# code and use this instead:
#
#   spec.version = Module.new.tap do |mod|
#     load("lib/memo_wise/version.rb", mod)
#   end::MemoWise::VERSION
load "lib/memo_wise/version.rb"
gem_version = MemoWise.send(:remove_const, :VERSION)

Gem::Specification.new do |spec|
  spec.name     = "memo_wise"
  spec.version  = gem_version
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
