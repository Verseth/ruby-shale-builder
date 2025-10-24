# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.3] - 2025-10-24

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.8.2...v0.8.3)

### Changes
- Make `name` in `Shale::Builder::NestedValidations#import_errors` an optional kwarg

## [0.8.3] - 2025-10-24

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.8.2...v0.8.3)

### Changes
- Fix `valid?`

## [0.8.2] - 2025-10-24

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.8.1...v0.8.2)

### Changes
- Fix infinite recursion in `Shale::Builder::NestedValidations#validatable_attribute_names`

## [0.8.1] - 2025-10-24

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.8.0...v0.8.1)

### Changes
- Change `Shale::Type::Value` generated type from `Object` to `T.untyped`

## [0.8.0] - 2025-10-24

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.7.1...v0.8.0)

### Changes
- Add `Shale::Builder::NestedValidations#validatable_attribute_names`, `Shale::Builder::NestedValidations#nested_attr_name_separator`, `Shale::Builder::NestedValidations#import_errors`

## [0.7.1] - 2025-10-17

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.7.0...v0.7.1)

### Changes
- Make `Shale::Builder::NestedValidations::nested_attr_name_separator` inheritable

## [0.7.0] - 2025-10-17

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.6.4...v0.7.0)

### Changes
- Add `Shale::Builder::NestedValidations::nested_attr_name_separator` that lets users customise the nested attribute name separator in validation errors

## [0.6.4] - 2025-10-16

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.6.3...v0.6.4)

### Changes
- Fix `Shale::Builder::AssignedAttributes` and add additional tests

## [0.6.3] - 2025-10-16

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.6.2...v0.6.3)

### Changes
- Improve `Shale::Builder::AssignedAttributes` to handle assignment in methods like `from_hash`

## [0.6.2] - 2025-10-16

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.6.0...v0.6.2)

### Changes
- Fix `Shale::Builder#inject_context`
- Add `Shale::Builder::S` alias to `Shale::Type`

## [0.6.0] - 2025-10-16

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.5.1...v0.6.0)

### Changes
- Add `Shale::Builder::mapper_attributes`, `Shale::Builder::mapper_attributes!`, `Shale::Builder::builder_attributes`, `Shale::Builder::builder_attributes!`
- Add `Shale::Builder#inject_context`

## [0.5.1] - 2025-10-15

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.5.0...v0.5.1)

### Changes
- Add `return_type` and `setter_type` overrides per attribute

## [0.5.0] - 2025-10-15

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.4.1...v0.5.0)

### Changes
- Add `Shale::Builder::AssignedAttributes` module which grants a shale mapper class with the ability to record which attributes have been assigned
- Add `Shale::Builder::Value` which represents a value of a shale attribute.
- Add `Shale::Builder#attribute_values`, a method that returns an array of `Shale::Builder::Value` objects for each attribute.

## [0.4.1] - 2025-10-14

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.4.0...v0.4.1)

### Changes
- Fix `Shale::Builder::alias_attribute`, improve changelog

## [0.4.0] - 2025-10-14

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.3.0...v0.4.0)

### Changes
- Add `Shale::Builder::NestedValidations`
- Add `Shale::Builder#alias_attribute`

## [0.3.0] - 2025-09-24

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.2.1...v0.3.0)

### Changes
- Add support for `BigDecimal`

## [0.2.1] - 2024-07-16

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.2.0...v0.2.1)

### Changes
- Add additional sorbet type documentation

## [0.2.0] - 2024-06-11

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.9...v0.2.0)

### Changes
- Add support for `return_type` and `setter_type` in custom primitive shale types
- Add a more thorough description of sorbet and tapioca support in the README

## [0.1.9] - 2024-06-03

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.8...v0.1.9)

### Changes
- Fix the signature of `new` class method

## [0.1.8] - 2024-05-15

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.7...v0.1.8)

### Changes
- Sort attribute names in the tapioca compiler

## [0.1.7] - 2024-05-13

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.6...v0.1.7)

### Changes
- Drop support for Ruby 3.0
- Add support for Ruby 3.3

## [0.1.6] - 2024-05-13

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.5...v0.1.6)

### Changes
- Add support for doc strings in the tapioca compiler

## [0.1.5] - 2024-05-13

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.4...v0.1.5)

### Changes
- Fix a bug in the tapioca compiler

## [0.1.4] - 2024-05-13

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.3...v0.1.4)

### Changes
- Add a tapioca compiler for shale and shale builder

## [0.1.3] - 2023-11-23

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.2...v0.1.3)

### Changes
- Change shale version dependency from `< 1.0` to `< 2.0`

## [0.1.2] - 2023-10-11

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.1...v0.1.2)

### Changes
- Add support for collections
- Drop support for Ruby 2.7

## [0.1.1] - 2023-02-22

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.1.0...v0.1.1)

### Changes
- Add support for inheritance

## [0.1.0] - 2023-02-21

[Diff](https://github.com/Verseth/ruby-shale-builder/compare/v0.0.0...v0.1.0)

### Changes
- Initial release
