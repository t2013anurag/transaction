# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.5] - 2019-07-19

### Added
  - specs for update_attributes

### Changed
  - Raise ArgumentError if invalid attributes are passed in `update_attributes`
  - Raise StandardError if transaction has expired.
  - specs for `refresh!`


## [0.1.5] - 2019-07-19

### Added
  - Readme examples

### Changed
  - Transaction finished with default status `success`

## [0.1.4] - 2019-07-18

### Added
  - Support for ruby >= 2.4

### Changed
  - Rake to 12.3


## [0.1.3] - 2019-07-18

### Added
  - Codeclimate configuration.
  - Rubocop autofixes and exclude patterns.
  - Enable test coverage.


## [0.1.2] - 2019-07-18

### Added
  - Travis configuration.
  - Unit tests for methods.

### Changed
  - Status is now always returned as a string (not a sym)

## [0.1.1] - 2019-07-18

### Added
  - Changelog to track version changes.

### Removed
  - Removed redis from gemfile. Use it as a runtime dependency.

### Changed
  - Default attributes


## [0.1.0] - 2019-07-17

### Added
  - Base library
  - Redis connection
