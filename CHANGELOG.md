# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Updated
- Improve performance across the board by:
  - removing `Hash#fetch`
  - using `Array#hash`
  - avoiding multi-layer hash lookups for multi-argument methods
  - optimizing for truthy results
- Add `dry-core` to benchmarks in README
### Fixed
- Fix usage on module singleton classes
- Fix usage on module which would be extended by other classes

## [1.0.0] - 2021-06-24
### Added
- Support for `.preset_memo_wise` on class methods
- Support for `.reset_memo_wise` on class methods
### Updated
- Improved performance for common cases by reducing array allocations

## [0.4.0] - 2021-04-30
### Added
- Documentation of confusing module test behavior
- Support using MemoWise in classes with keyword arguments in the initializer
- Support Marshal dump/load of classes using MemoWise

## [0.3.0] - 2021-02-11
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

[Unreleased]: https://github.com/panorama-ed/memo_wise/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/panorama-ed/memo_wise/compare/v0.4.0...v1.0.0
[0.4.0]: https://github.com/panorama-ed/memo_wise/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/panorama-ed/memo_wise/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/panorama-ed/memo_wise/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/panorama-ed/memo_wise/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/panorama-ed/memo_wise/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/panorama-ed/memo_wise/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/panorama-ed/memo_wise/releases/tag/v0.0.1
