# `MemoWise`

[![Tests](https://github.com/panorama-ed/memo_wise/workflows/Main/badge.svg)](https://github.com/panorama-ed/memo_wise/actions?query=workflow%3AMain)
[![Code Coverage](https://codecov.io/gh/panorama-ed/memo_wise/branch/main/graph/badge.svg)](https://codecov.io/gh/panorama-ed/memo_wise/branches/main)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/panorama-ed/memo_wise)
[![Inline docs](http://inch-ci.org/github/panorama-ed/memo_wise.svg?branch=main)](http://inch-ci.org/github/panorama-ed/memo_wise)
[![Gem Version](https://img.shields.io/gem/v/memo_wise.svg)](https://rubygems.org/gems/memo_wise)
[![Gem Downloads](https://img.shields.io/gem/dt/memo_wise.svg)](https://rubygems.org/gems/memo_wise)


## Why `MemoWise`?

`MemoWise` is **the wise choice for Ruby memoization**, featuring:

  * Fast performance of memoized reads (with [benchmarks](#benchmarks))
  * Support for [resetting](https://rubydoc.info/github/panorama-ed/memo_wise/MemoWise#reset_memo_wise-instance_method) and [presetting](https://rubydoc.info/github/panorama-ed/memo_wise/MemoWise#preset_memo_wise-instance_method) memoized values
  * Support for memoization on frozen objects
  * Support for memoization of class and module methods (COMING SOON!)
  * Full [documentation](https://rubydoc.info/github/panorama-ed/memo_wise/MemoWise) and [test coverage](https://codecov.io/gh/panorama-ed/memo_wise)!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'memo_wise'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install memo_wise

## Usage

When you `prepend MemoWise` within a class or module, `MemoWise` exposes three
methods:

- [`memo_wise`](https://rubydoc.info/github/panorama-ed/memo_wise/MemoWise#memo_wise-class_method)
- [`preset_memo_wise`](https://rubydoc.info/github/panorama-ed/memo_wise/MemoWise#preset_memo_wise-instance_method)
- [`reset_memo_wise`](https://rubydoc.info/github/panorama-ed/memo_wise/MemoWise#reset_memo_wise-instance_method)

```ruby
class Example
  prepend MemoWise
  def slow_value(x)
    sleep x
    x
  end
  memo_wise :slow_value
end

ex = Example.new
ex.slow_value(2) # => 2 # Sleeps for 2 seconds before returning
ex.slow_value(2) # => 2 # Returns immediately because the result is memoized

ex.reset_memo_wise(:slow_value) # Resets all memoized results for slow_value
ex.slow_value(2) # => 2 # Sleeps for 2 seconds before returning
ex.slow_value(2) # => 2 # Returns immediately because the result is memoized
# NOTE: Memoization can also be reset for all methods, or for just one argument.

ex.preset_memo_wise(:slow_value, 3) { 4 } # Store 4 as the result for slow_value(3)
ex.slow_value(3) # => 4 # Returns immediately because the result is memoized
ex.reset_memo_wise # Resets all memoized results for all methods on ex
```

Methods which take implicit or explicit block arguments cannot be memoized.

For more usage details, see our detailed [documentation](#documentation).

## Benchmarks

Memoized value retrieval time using Ruby 2.7.2 and
[`benchmark-ips`](https://github.com/evanphx/benchmark-ips) 2.8.3:

|Method arguments|**`memo_wise` (0.1.0)**|`memery` (1.3.0)|`memoist` (0.16.2)|`memoized` (1.0.2)|`memoizer` (1.0.3)|
|--|--|--|--|--|--|
|`()` (none)|**baseline**|11.99x slower|2.53x slower|1.29x slower|3.01x slower|
|`(a, b)`|**baseline**|1.94x slower|2.28x slower|1.80x slower|1.96x slower|
|`(a:, b:)`|**baseline**|2.20x slower|2.37x slower|2.15x slower|2.18x slower|
|`(a, b:)`|**baseline**|1.51x slower|1.68x slower|1.46x slower|1.54x slower|
|`(a, *args)`|**baseline**|2.00x slower|2.33x slower|1.96x slower|1.97x slower|
|`(a:, **kwargs)`|**baseline**|1.94x slower|2.12x slower|1.87x slower|1.96x slower|
|`(a, *args, b:, **kwargs)`|**baseline**|1.92x slower|2.15x slower|1.90x slower|1.91x slower|

Benchmarks are run in GitHub Actions and updated in every PR that changes code.

You can run benchmarks yourself with:

```bash
$ cd benchmarks
$ bundle install
$ bundle exec ruby benchmarks.rb
```

If your results differ from what's posted here,
[let us know](https://github.com/panorama-ed/memo_wise/issues/new)!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Documentation

### Documentation is Automatically Generated

We maintain API documentation using [YARD](https://yardoc.org/), which is
published automatically at
[RubyDoc.info](https://rubydoc.info/github/panorama-ed/memo_wise/MemoWise). To
edit documentation locally and see it rendered in your browser, run:

```bash
bundle exec yard server
```

### Documentation Examples are Automatically Tested

We use [yard-doctest](https://github.com/p0deje/yard-doctest) to test all
code examples in our YARD documentation. To run `doctest` locally:

```bash
bundle exec yard doctest
```

## Contributing

[Bug reports](https://github.com/panorama-ed/memo_wise/issues) and
[pull requests](https://github.com/panorama-ed/memo_wise/pulls) are welcome on GitHub at
https://github.com/panorama-ed/memo_wise. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/panorama-ed/memo_wise/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `MemoWise` project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/panorama-ed/memo_wise/blob/main/CODE_OF_CONDUCT.md).
