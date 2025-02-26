# Changelog

All notable changes to this project will be documented in this file, which
follows a format inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/panorama-ed/memo_wise/compare/v1.11.0...HEAD)

**Gem enhancements:** none

_No breaking changes!_

**Project enhancements:** none

## [v1.11.0](https://github.com/panorama-ed/memo_wise/compare/v1.10.0...v1.11.0)

**Gem enhancements:**

- Stopped `preset_memo_wise` (and `reset_memo_wise` with an argument) from raising errors when called on module methods [[#377]](https://github.com/panorama-ed/memo_wise/pull/377)
- Changed internal `require`s to `require_relative` to make code less dependent on the load path [[#350](https://github.com/panorama-ed/memo_wise/pull/350)]

_Breaking changes:_
- Removed Ruby 2.5 (EOL) and 2.6 (EOL) support to allow upgrading rexml dependency version from a version that includes a [CVE](https://www.ruby-lang.org/en/news/2024/10/28/redos-rexml-cve-2024-49761/) [[#362]](https://github.com/panorama-ed/memo_wise/pull/362)

**Project enhancements:**

- Updated `webrick` in `Gemfile.lock` to resolve CVE-2024-47220. This vulnerability does not impact `memo_wise` users.
- Allowed more tests to run on JRuby [[#377]](https://github.com/panorama-ed/memo_wise/pull/377)

## [v1.10.0](https://github.com/panorama-ed/memo_wise/compare/v1.9.0...v1.10.0)

**Gem enhancements:**

- Reduced gem size from 173 kB compressed (312 kB unpacked) to 18.5 kB (68 kB unpacked) [[#345](https://github.com/panorama-ed/memo_wise/pull/345)]

_No breaking changes!_

**Project enhancements:**

- Updated official test coverage to support Ruby 3.3 [[#335](https://github.com/panorama-ed/memo_wise/pull/335)]
- Added `alt_memery` and `memoist3` to benchmarks [[#339](https://github.com/panorama-ed/memo_wise/pull/339)]
- Updated benchmark results in `README.md` to Ruby 3.3.5 [[#339](https://github.com/panorama-ed/memo_wise/pull/339)]

## [v1.9.0](https://github.com/panorama-ed/memo_wise/compare/v1.8.0...v1.9.0)

**Gem enhancements:**

- Fixed a bug that overwrote existing self.extended method definitions. [[#324](https://github.com/panorama-ed/memo_wise/pull/314)]
- Fixed a bug that overwrote existing self.inherited method definitions. [[#325](https://github.com/panorama-ed/memo_wise/pull/315)]

_Breaking changes:_
- Removed Ruby 2.4 (EOL) support to allow upgrading rexml dependency version from a version that includes a [CVE](https://www.ruby-lang.org/en/news/2024/05/16/dos-rexml-cve-2024-35176/) [[#336](https://github.com/panorama-ed/memo_wise/pull/336)]

**Project enhancements:**

- Fixed `bundle exec yard server --reload` and related documentation [[#333](https://github.com/panorama-ed/memo_wise/pull/333)]
- Fixed Codecov rate limiting errors affecting pull requests by upgrading `codecov/codecov-action` and using a Codecov token [[#317](https://github.com/panorama-ed/memo_wise/pull/317)]

## [v1.8.0](https://github.com/panorama-ed/memo_wise/compare/v1.7.0...v1.8.0) - 2023-10-25

**Gem enhancements:**

- In Ruby3.2+, for singleton classes, use `#attached_object` instead of `ObjectSpace` [[#318](https://github.com/panorama-ed/memo_wise/pull/318)]

_No breaking changes!_

**Project enhancements:**

- Switched RuboCop configuration from `panolint` to `panolint-ruby` [[#312](https://github.com/panorama-ed/memo_wise/pull/312)]
- Updated benchmark results in `README.md` to Ruby 3.2.2 and 2.7.8 [[#313](https://github.com/panorama-ed/memo_wise/pull/297)]
- Updated `Dry::Core` gem version to 1.0.0 in benchmarks [[#297](https://github.com/panorama-ed/memo_wise/pull/297)]
- Updated `Memery` gem version to 1.5.0 in benchmarks [[#313](https://github.com/panorama-ed/memo_wise/pull/313)]
- Updated `Memoized` gem version to 1.1.1 in benchmarks [[#288](https://github.com/panorama-ed/memo_wise/pull/288)]
- Reorganized `CHANGELOG.md` for improved clarity and completeness [[#282](https://github.com/panorama-ed/memo_wise/pull/282)]

## [v1.7.0](https://github.com/panorama-ed/memo_wise/compare/v1.6.0...v1.7.0) - 2022-04-04

**Gem enhancements:**

- Optimized memoized lookups for methods with multiple required arguments
  [[#276](https://github.com/panorama-ed/memo_wise/pull/276)]

_No breaking changes!_

**Project enhancements:**

- Added benchmarking against GitHub `main` branch to CI [[#274](https://github.com/panorama-ed/memo_wise/pull/274)]

## [v1.6.0](https://github.com/panorama-ed/memo_wise/compare/v1.5.0...v1.6.0) - 2022-01-24

**Gem enhancements:**

- Fixed a bug relating to inheritance of classes which include a module which
  `prepend`s `MemoWise` [[#262](https://github.com/panorama-ed/memo_wise/pull/262)]

_No breaking changes!_

**Project enhancements:**

- Updated official test coverage to support Ruby 3.1 [[#263](https://github.com/panorama-ed/memo_wise/pull/263)]

## [v1.5.0](https://github.com/panorama-ed/memo_wise/compare/v1.4.0...v1.5.0) - 2021-12-17

**Gem enhancements:**

- Removed thread-unsafe optimization which optimized for returning "truthy" results
  [[#255](https://github.com/panorama-ed/memo_wise/pull/255)]
- Switched to a simpler internal data structure to fix several classes of bugs related to inheritance
  that the previous few versions were unable to sufficiently address
  [[#250](https://github.com/panorama-ed/memo_wise/pull/250)]

_No breaking changes!_

**Project enhancements:**

- Expanded thread-safety testing [[#254](https://github.com/panorama-ed/memo_wise/pull/254)]

## [v1.4.0](https://github.com/panorama-ed/memo_wise/compare/v1.3.0...v1.4.0) - 2021-12-10

**Gem enhancements:**

- Fixed several bugs related to classes inheriting memoized methods from multiple modules or a parent class
  [[#241](https://github.com/panorama-ed/memo_wise/pull/241)]

_No breaking changes!_

**Project enhancements:**

- Added TruffleRuby tests to CI [[#237](https://github.com/panorama-ed/memo_wise/pull/237)]

## [v1.3.0](https://github.com/panorama-ed/memo_wise/compare/v1.2.0...v1.3.0) - 2021-11-22

**Gem enhancements:**

- Fixed thread-safety issue in concurrent calls to a zero-arg method in an unmemoized state (which resulted in a `nil` value being incorrectly returned in one thread) [[#230](https://github.com/panorama-ed/memo_wise/pull/230)]
- Fixed bugs related to child classes inheriting from parent classes that use `MemoWise`
  [[#229](https://github.com/panorama-ed/memo_wise/pull/229)]

_No breaking changes!_

**Project enhancements:**

- Added thread-safety test [[#225](https://github.com/panorama-ed/memo_wise/pull/225)]

## [v1.2.0](https://github.com/panorama-ed/memo_wise/compare/v1.1.0...v1.2.0) - 2021-11-10

**Gem enhancements:**

- Optimized memoized lookups for all methods by using an outer array instead of a hash
  [[#211](https://github.com/panorama-ed/memo_wise/pull/211),
  [#210](https://github.com/panorama-ed/memo_wise/pull/210),
  [#219](https://github.com/panorama-ed/memo_wise/pull/219)]
- Removed an internal optimization using `#hash` due to the potential of hash collisions
  [[#219](https://github.com/panorama-ed/memo_wise/pull/219)]
- Changed internal local variable names to avoid name collisions with memoized method arguments
  [[#221](https://github.com/panorama-ed/memo_wise/pull/221)]

_No breaking changes!_

**Project enhancements:**

- Added nuance to benchmarks [[#214](https://github.com/panorama-ed/memo_wise/pull/214)]
- Significantly sped up tests [[#206](https://github.com/panorama-ed/memo_wise/pull/206)]

## [v1.1.0](https://github.com/panorama-ed/memo_wise/compare/v1.0.0...v1.1.0) - 2021-07-29

**Gem enhancements:**

- Fixed buggy behavior in module singleton classes and modules extended by other classes
  [[#185](https://github.com/panorama-ed/memo_wise/pull/185)]
- Optimized memoized lookups in many cases, using a variety of optimizations
  [[#189](https://github.com/panorama-ed/memo_wise/pull/189)]

_No breaking changes!_

**Project enhancements:**

- Added the `dry-core` gem to benchmarks [[#187](https://github.com/panorama-ed/memo_wise/pull/187)]

## [v1.0.0](https://github.com/panorama-ed/memo_wise/compare/v0.4.0...v1.0.0) - 2021-06-24

**Gem enhancements:**

- Class methods are now supported by `#preset_memo_wise` and `#reset_memo_wise`
  [[#134](https://github.com/panorama-ed/memo_wise/pull/134),
  [#145](https://github.com/panorama-ed/memo_wise/pull/145)]
- Optimized memoized lookups in many cases [[#143](https://github.com/panorama-ed/memo_wise/pull/143)]
- Implemented `.instance_method` to proxy original method parameters
  [[#163](https://github.com/panorama-ed/memo_wise/pull/163)]

_No breaking changes!_

**Project enhancements:** none

## [v0.4.0](https://github.com/panorama-ed/memo_wise/compare/v0.3.0...v0.4.0) - 2021-04-30

**Gem enhancements:**

- Methods on objects that are serialized/deserialized with `Marshal` can now be memoized
  [[#138](https://github.com/panorama-ed/memo_wise/pull/138)]
- Classes with keyword arguments in `#initialize` can now support memoization
  [[#125](https://github.com/panorama-ed/memo_wise/pull/125)]

_No breaking changes!_

**Project enhancements:**

- Added [`A Note on Testing`](https://github.com/panorama-ed/memo_wise#a-note-on-testing) section of `README.md`
  [[#123](https://github.com/panorama-ed/memo_wise/pull/123)]

## [v0.3.0](https://github.com/panorama-ed/memo_wise/compare/v0.2.0...v0.3.0) - 2021-02-11

**Gem enhancements:**

- Class methods can now be memoized [[#83](https://github.com/panorama-ed/memo_wise/pull/83)]
- Instance methods on objects created with `Class#allocate` can now be memoized
  [[#99](https://github.com/panorama-ed/memo_wise/pull/99)]
- Fixed `#reset_memo_wise` for private methods [[#111](https://github.com/panorama-ed/memo_wise/pull/111)]

_No breaking changes!_

**Project enhancements:**

- Added the project logo [[#81](https://github.com/panorama-ed/memo_wise/pull/81)]
- Added `CHANGELOG.md` and version tags [[#78](https://github.com/panorama-ed/memo_wise/pull/78)]
- Documented release procedure in `README.md` [[#114](https://github.com/panorama-ed/memo_wise/pull/114)]
- Updated CI testing and benchmarks for Ruby 3.0 [[#101](https://github.com/panorama-ed/memo_wise/pull/101)]

## [v0.2.0](https://github.com/panorama-ed/memo_wise/compare/v0.1.2...v0.2.0) - 2020-10-28

**Gem enhancements:**

- Added `#preset_memo_wise` to preset memoization values [[#30](https://github.com/panorama-ed/memo_wise/pull/30)]

_Breaking changes:_

- Removed `#reset_all_memo_wise` (use `#reset_memo_wise` instead)
  [[#52](https://github.com/panorama-ed/memo_wise/pull/52)]

**Project enhancements:**

- YARD docs are now generated [[#52](https://github.com/panorama-ed/memo_wise/pull/52),
  [#55](https://github.com/panorama-ed/memo_wise/pull/55),
  [#57](https://github.com/panorama-ed/memo_wise/pull/57)]
- 100% code coverage is now enforced [[#62](https://github.com/panorama-ed/memo_wise/pull/62)]

## [v0.1.2](https://github.com/panorama-ed/memo_wise/compare/v0.1.1...v0.1.2) - 2020-10-01

**Gem enhancements:**

- Optimized memoized lookups with internal data structure and method signature changes
  [[#28](https://github.com/panorama-ed/memo_wise/pull/28), [#32](https://github.com/panorama-ed/memo_wise/pull/32)]

_No breaking changes!_

**Project enhancements:**

- Tests now assert that memoization works with the `Values` gem
  [[#46](https://github.com/panorama-ed/memo_wise/pull/46)]
- Added `README.md` badges for tests, docs, and RubyGems
  [[#47](https://github.com/panorama-ed/memo_wise/pull/47)]

## [v0.1.1](https://github.com/panorama-ed/memo_wise/compare/v0.1.0...v0.1.1) - 2020-08-03

**Gem enhancements:**

- `#reset_memo_wise` can now reset memoization for specific method arguments
  [[#20](https://github.com/panorama-ed/memo_wise/pull/20)]

_No breaking changes!_

**Project enhancements:**

- Added benchmarks to compare `MemoWise` to other Ruby memoization gems
  [[#13](https://github.com/panorama-ed/memo_wise/pull/13)]

## [v0.1.0](https://github.com/panorama-ed/memo_wise/compare/v0.0.1...v0.1.0) - 2020-07-20

**Gem enhancements:**

- Added `#memo_wise`, which enables method memoization [[#4](https://github.com/panorama-ed/memo_wise/pull/4)]
- Added `#reset_memo_wise` and `#reset_all_memo_wise`, which reset memoization
  [[#4](https://github.com/panorama-ed/memo_wise/pull/4)]

_No breaking changes!_

**Project enhancements:** none

## [v0.0.1](https://github.com/panorama-ed/memo_wise/releases/tag/v0.0.1) - 2020-06-29

*This version does not provide memoization functionality; it simply includes
project scaffolding.*
