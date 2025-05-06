# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "memo_wise"

  # After loading the `VERSION` constant, save it to a variable to use in this
  # gemspec and then undefine it. This allows benchmarks to compare multiple
  # versions of MemoWise against each other without inadvertently sharing the
  # same `VERSION` constant.
  # NOTE: In future Ruby versions, we can avoid this complexity and the use of
  # `GemBench` in `benchmarks.rb` by using namespaces. For more context, see:
  # https://bugs.ruby-lang.org/issues/21311
  # NOTE: It's important that we use `load` instead of `require_relative`
  # because the latter only loads a file once, and so by undefining the
  # `VERSION` constant we can make it difficult to access that value again
  # later. For more context, see: https://github.com/panorama-ed/memo_wise/pull/370#issuecomment-2560268423
  spec.version = Module.new.tap do |mod|
    # NOTE: We fully qualify `Kernel` here because Rubygems defines its own
    # `load` method, which is used by default when this code is executed by
    # `gem build memo_wise.gemspec`. That `load` method does not support the
    # optional "wrap" parameter we pass through as `mod`. For more context, see:
    # https://github.com/simplecov-ruby/simplecov/issues/557#issuecomment-2630782358
    Kernel.load("lib/memo_wise/version.rb", mod)
  end::MemoWise::VERSION
  spec.summary = "The wise choice for Ruby memoization"
  spec.homepage = "https://github.com/panorama-ed/memo_wise"
  spec.license = "MIT"

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

  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.0")

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{CHANGELOG.md,LICENSE.txt,README.md,lib/**/*.rb}")
  spec.require_paths = ["lib"]

  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "changelog_uri" => "https://github.com/panorama-ed/memo_wise/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/panorama-ed/memo_wise"
  }
end
