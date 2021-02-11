# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Changelog and tags
- Logo
- Memoization of class methods
- Support for instances created with `Class#allocate`
- Official testing and benchmarks for Ruby 3.0
- Release procedure for gem

## [0.2.0] - 2020-10-28
### Added
- `#preset_memo_wise` to preset memoization values
- YARD docs
- Code coverage setup, badge, tests to ensure 100% coverage

## [0.1.2] - 2020-10-01
### Added
- Tests to assert memoization works with Values gem
- Badges for tests, docs and gem

### Changed
- Internal data structure for memoization is a nested hash
- Separate `*args` and `**kwargs` in method signatures

## [0.1.1] - 2020-08-03
### Added
- Benchmarks comparing `MemoWise` to other Ruby memoization gems
- `#reset_memo_wise` resets memoization for specific arguments for methods

## [0.1.0] - 2020-07-20
### Added
- `#memo_wise` defined to enable memoization
- `#reset_memo_wise` and `#reset_all_memo_wise` defined to reset memoization

## [0.0.1] - 2020-06-29
### Added
- Initial gem project structure
- Panolint
- Dependabot setup

[Unreleased]: https://github.com/panorama-ed/memo_wise/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/panorama-ed/memo_wise/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/panorama-ed/memo_wise/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/panorama-ed/memo_wise/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/panorama-ed/memo_wise/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/panorama-ed/memo_wise/releases/tag/v0.0.1
