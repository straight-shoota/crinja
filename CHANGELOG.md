# Changelog
All notable changes to Crinja will be documented in this file.

## 0.9.0 (2025-01-20)

* Compatibility with Crystal 1.19 ([#94])
* Integrate `JSON::Any` and `YAML::Any` as `Crinja::Object` ([#18])
* **(breaking)** Resolver uses nilable accessor method `#[]?` instead of `#[]` ([#48])
* Windows support for `striptags` (via XML) ([#64])

[#94]: https://github.com/straight-shoota/crinja/pull/94
[#18]: https://github.com/straight-shoota/crinja/pull/18
[#48]: https://github.com/straight-shoota/crinja/pull/48
[#64]: https://github.com/straight-shoota/crinja/pull/64

## 0.8.1 (2023-03-06)

Compatibility with PCRE2 (Crystal 1.8)

## 0.8.0 (2021-07-16)

Compatbility with Crystal 1.1

* Updates dependencies with more relaxed version restrictions
* Removes autogeneration for predicate method without suffix to avoid duplicate when conditions
* Fixes type bugs discovered through Crystal 1.1
* Adds GitHub actions
* Fixes some minor documentation bugs

## 0.7.0 (2021-02-06)

* Improves `TagCycleException`
* Adds `do` tag (#33, thanks @n-rodriguez)
* Adds compatibility with Crystal >= 0.35.1 and Shards >= 0.11.0
* Adds support for mapping predicate methods
* Smaller cleanup and improvements

## 0.6.1 (2020-06-09)

Compatibility with Crystal 0.35.0

## 0.6.0 (2020-04-03)

Compatibility with Crystal 0.34.0

* Improvements to Makefile and CI setup
* Use `Log` framework from Crystal 0.34.0

## 0.5.1 (2020-01-14)

This release brings compatibility with Crystal 0.32.1

## 0.5.0 (2019-06-07)

This release brings compatibility with Crystal 0.29.0

* Rename `FeatureLibrary#aliasses` to `#aliases`
* Add experimental support for liquid syntax with `Crinja.liquid_support`

## 0.4.1 (2019-01-01)

This release doesn't add any new features but fixes compatibility with Crystal 0.27.0.

## 0.4.0 (2018-10-16)

This release comes with some refactorings of the public API to make it easier to use.
Most prominently, annotation based autogenerator for exposing object properties to the Crinja runtime were added.

```cr
require "crinja"

class User
  include Crinja::Object::Auto

  @[Crinja::Attribute]
  def name : String
    "john paul"
  end
end

Crinja.new.from_string("{{ user.name }}").render({"user" => User.new}) # => "john paul"
```

Autogeneration of `crinja_call` will be left for the next release.

Most other changes involve the CI infrastructure, with Circle CI taking over the main load from travis.

* **(breaking-change)** Replaced `Crinja::PyObject` by `Crinja::Object` and renamed hook methods to `crinja_attribute` and `crinja_call`. `getitem` hook has been removed.
* **(breaking-change)** Added `Crinja::Object::Auto` for generating automatic bindings for `crinja_attribute` (previously provided by `Crinja::PyObject.getattr`). The behaviour can be configured using annotations `Crinja::Attribute` and `Crinja::Attributes`.
* **(breaking-change)** Renamed `Crinja::Callable::Arguments` to `Crinja::Arguments`. The API has been simplified by removing unused setters.
* **(breaking-change)** Removed `Crinja::Arguments#[](key : Symbol)`. Use a string key instead.
* **(breaking-change)** Renamed `Crinja::Callable::Arguments::UnknownArgumentException` to `Crinja::Arguments.:UnknownArgumentError`.
* **(breaking-change)** Renamed `Crinja::Callable::Arguments::ArgumentError` to `Crinja::Arguments::Error`.
* **(breaking-change)** Renamed `Crinja::PyTuple` to `Crinja::Tuple`.
* **(breaking-change)** Updated `BakedFileLoader` for compatibility with `baked_file_system 0.9.6`
* Upgraded to Crystal 0.26.1.
* Fixed number filters (`int` and `float`) to not rely on raising an error.
* Fixed `generate-docs` script.
* Added `Makefile`.
* Added Circle CI integration with nighly builds testing with Crystal nightly.
* Added integration tests for usage examples (`./examples`) in travis-ci and Circle CI.
* Added automatic docs generation to circle CI workflow and removed it from travis-ci.
* Added formatter checks to CI checks.
* Added preliminary Windows support by removing dependency on `xml`.
* Added this changelog.
* Improved reference to exmples in README.

## 0.3.0 (2018-06-29)

This release updated Crinja to work with Crystal 0.25.1

Notable changes:

* **(breaking-change)** Renamed `Crinja::Environment` to just `Crinja`
* **(breaking-change)** Removed `Crinja::Type` in favour of `Crinja::Value` to avoid recursive aliases and reduce a lot of `.as(Type)` castings all over the place. This change was similar to `JSON::Type` -> `JSON::Any` in Crystal 0.25.0.
* **(breaking-change)** Removed `Crinja::Bindings`. Some methods are obsolete with `Crinja::Value`, others moved to `Crinja` namespace.
* Added dedicated documentation of [*Template Syntax*](https://github.com/straight-shoota/crinja/blob/5b1a3c30fac48f8bfccab5043fbda209f7859046/TEMPLATE_SYNTAX.md)

## 0.2.1 (2018-01-01)

