
<p>
  <img src="logo/logo.png" width="175"/>
</p>

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
  * Support for memoization of class and module methods
  * Support for inheritance of memoized class and instance methods
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

  private

  # maintains privacy of the memoized method
  def private_slow_method(x)
    sleep x
    x
  end
  memo_wise :private_slow_method
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

The same three methods are exposed for class methods as well:

```ruby
class Example
  prepend MemoWise

  def self.class_slow_value(x)
    sleep x
    x
  end
  memo_wise self: :class_slow_value
end

Example.class_slow_value(2) # => 2 # Sleeps for 2 seconds before returning
Example.class_slow_value(2) # => 2 # Returns immediately because the result is memoized

Example.reset_memo_wise(:class_slow_value) # Resets all memoized results for class_slow_value

Example.preset_memo_wise(:class_slow_value, 3) { 4 } # Store 4 as the result for slow_value(3)
Example.class_slow_value(3) # => 4 # Returns immediately because the result is memoized
Example.reset_memo_wise # Resets all memoized results for all methods on class
```

**NOTE:** Methods which take implicit or explicit block arguments cannot be
memoized.

For more usage details, see our detailed [documentation](#documentation).

## Benchmarks

Benchmarks are run in GitHub Actions, and the tables below are updated with every code change. **Values >1.00x represent how much _slower_ each gem’s memoized value retrieval is than the latest commit of `MemoWise`**, according to [`benchmark-ips`](https://github.com/evanphx/benchmark-ips) (2.9.2).

Results using Ruby 3.0.3:

|Method arguments|`Dry::Core`\* (0.7.1)|`Memery` (1.4.0)|
|--|--|--|
|`()` (none)|1.42x|18.07x|
|`(a)`|2.31x|11.30x|
|`(a, b)`|0.46x|2.04x|
|`(a:)`|2.15x|20.31x|
|`(a:, b:)`|0.48x|4.25x|
|`(a, b:)`|0.47x|4.05x|
|`(a, *args)`|0.87x|1.96x|
|`(a:, **kwargs)`|0.79x|3.02x|
|`(a, *args, b:, **kwargs)`|0.60x|1.57x|

\* `Dry::Core`
[may cause incorrect behavior caused by hash collisions](https://github.com/dry-rb/dry-core/issues/63).

Results using Ruby 2.7.5 (because these gems raise errors in Ruby 3.x):

|Method arguments|`DDMemoize` (1.0.0)|`Memoist` (0.16.2)|`Memoized` (1.0.2)|`Memoizer` (1.0.3)|
|--|--|--|--|--|
|`()` (none)|37.00x|3.49x|1.72x|4.33x|
|`(a)`|29.10x|19.52x|14.74x|16.96x|
|`(a, b)`|3.29x|2.34x|1.85x|2.04x|
|`(a:)`|39.39x|31.54x|26.94x|28.40x|
|`(a:, b:)`|5.34x|4.43x|3.89x|4.06x|
|`(a, b:)`|4.99x|4.13x|3.56x|3.74x|
|`(a, *args)`|3.19x|2.30x|1.95x|1.99x|
|`(a:, **kwargs)`|2.91x|2.44x|2.11x|2.23x|
|`(a, *args, b:, **kwargs)`|2.11x|1.78x|1.66x|1.65x|

You can run benchmarks yourself with:

```bash
$ cd benchmarks
$ bundle install
$ bundle exec ruby benchmarks.rb
```

If your results differ from what's posted here,
[let us know](https://github.com/panorama-ed/memo_wise/issues/new)!

## Thread Safety

MemoWise makes the following **thread safety** guarantees on all supported Ruby
versions:

1. **Before** a value has been memoized

   * Contended calls from multiple threads...
      * May each call the original method
      * May return different valid results (when the method is nondeterministic,
        like `rand`)
      * Will memoize exactly one valid return value

2. **After** a value has been memoized

   * Contended calls from multiple threads...
     * Always return the same memoized value

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

We use [dokaz](https://github.com/zverok/dokaz) to test all code examples in
this README.md file, and all other non-code documentation. To run `dokaz`
locally:

```bash
bundle exec dokaz
```

### A Note on Testing

When testing memoized *module* methods, note that some testing setups will
reuse the same instance (which `include`s/`extend`s/`prepend`s the module)
across tests, which can result in confusing test failures when this differs from
how you use the code in production.

For example, Rails view helpers are modules that are commonly tested with a
[shared `view` instance](https://github.com/rails/rails/blob/291a3d2ef29a3842d1156ada7526f4ee60dd2b59/actionview/lib/action_view/test_case.rb#L203-L214). Rails initializes a new view instance for each web request so any view helper
methods would only be memoized for the duration of that web request, but in
tests (such as when using
[`rspec-rails`'s `helper`](https://github.com/rspec/rspec-rails/blob/main/lib/rspec/rails/example/helper_example_group.rb#L22-L27)),
the memoization may persist across tests. In this case, simply reset the
memoization between your tests with something like:

```ruby
after(:each) { helper.reset_memo_wise }
```

## Further Reading

We presented at RubyConf 2021:

- Achieving Fast Method Metaprogramming: Lessons from `MemoWise`
  ([slides](https://docs.google.com/presentation/d/1XgERQ0YHplwJKM3wNQwZn584d_9szYZp2WsDEXoY_7Y/edit?usp=sharing) /
  [benchmarks](https://gist.github.com/JacobEvelyn/17b7b000e50151c30eaea928f1fcdc11))

And we've written more about `MemoWise` in a series of blog posts:

- [Introducing: MemoWise](https://medium.com/building-panorama-education/introducing-memowise-51a5f0523489)
- [Optimizing MemoWise Performance](https://ja.cob.land/optimizing-memowise-performance)
- [Esosteric Ruby in MemoWise](https://jemma.dev/blog/esoteric-ruby-in-memowise)

## Logo

`MemoWise`'s logo was created by [Luci Cooke](https://www.lucicooke.com/). The
logo is licensed under a
[Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/deed.en).

## Contributing

[Bug reports](https://github.com/panorama-ed/memo_wise/issues) and
[pull requests](https://github.com/panorama-ed/memo_wise/pulls) are welcome on GitHub at
https://github.com/panorama-ed/memo_wise. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/panorama-ed/memo_wise/blob/main/CODE_OF_CONDUCT.md).

## Releasing

To make a new release of `MemoWise` to
[RubyGems](https://rubygems.org/gems/memo_wise), first install the release
dependencies (e.g. `rake`) as follows:

```shell
bundle config --local with 'release'
bundle install
```

Then carry out these steps:

1. Update `CHANGELOG.md`:
   - Add an entry for the upcoming version _x.y.z_
   - Add a link for this version's comparison to the bottom of `CHANGELOG.md`
   - Move content from _Unreleased_ to the upcoming version _x.y.z_
   - Commit with title `Update CHANGELOG.md for x.y.z`

2. Update `lib/memo_wise/version.rb`
   - Replace with upcoming version _x.y.z_
   - Commit with title `Bump version to x.y.z`

3. `bundle exec rake release`

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `MemoWise` project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/panorama-ed/memo_wise/blob/main/CODE_OF_CONDUCT.md).
