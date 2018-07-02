# Changelog
All notable changes to Crinja will be documented in this file.

## 0.3.0 (2018-06-29)

This release updated Crinja to work with Crystal 0.25.1

Notable changes:

* Renamed `Crinja::Environment` to just `Crinja`
* Removed `Crinja::Type` in favour of `Crinja::Value` to avoid recursive aliases and reduce a lot of `.as(Type)` castings all over the place. This change was similar to `JSON::Type` -> `JSON::Any` in Crystal 0.25.0.
* Removed `Crinja::Bindings`. Some methods are obsolete with `Crinja::Value`, others moved to `Crinja` namespace.
* Added automatic testing of usage examples (`./examples`) on travis-ci
* Added dedicated documentation of [*Template Syntax*](https://github.com/straight-shoota/crinja/blob/5b1a3c30fac48f8bfccab5043fbda209f7859046/TEMPLATE_SYNTAX.md)

## 0.2.1 (2018-01-01)

