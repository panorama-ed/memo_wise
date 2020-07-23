# MemoWise

TODO: Write clear description of MemoWise

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

TODO: Write usage instructions here

## Benchmarks

Memoized value retrieval time using Ruby 2.7.1 and
[`benchmark-ips`](https://github.com/evanphx/benchmark-ips) 2.8.2:

|Method arguments|**`memo_wise` (0.1.0)**|`memery` (1.3.0)|`memoist` (0.16.2)|`memoized` (1.0.2)|`memoizer` (1.0.3)|
|--|--|--|--|--|--|
|`()` (none)|**baseline**|11.57x slower|2.47x slower|1.16x slower|2.88x slower|
|`(a, b)`|**baseline**|2.02x slower|2.29x slower|1.83x slower|2.06x slower|
|`(a:, b:)`|**baseline**|2.34x slower|2.40x slower|2.17x slower|2.30x slower|
|`(a, b:)`|**baseline**|1.55x slower|1.61x slower|1.46x slower|1.51x slower|
|`(a, *args)`|**baseline**|1.99x slower|2.21x slower|1.93x slower|2.00x slower|
|`(a:, **kwargs)`|**baseline**|1.95x slower|2.07x slower|1.87x slower|1.97x slower|
|`(a, *args, b:, **kwargs)`|**baseline**|1.82x slower|1.98x slower|1.87x slower|1.91x slower|

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

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/panorama-ed/memo_wise. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/panorama-ed/memo_wise/blob/main/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MemoWise project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/panorama-ed/memo_wise/blob/main/CODE_OF_CONDUCT.md).
