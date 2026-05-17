# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Upcoming

## 2.0.1 - 2026-05-17

* Fix type inference error with modern D compilers.

## 2.0.0 - 2019-11-03

* Rewrite the library.

## 1.6.1 - 2016-05-22

* Add a channel argument to the mediator hooks.

## 1.6.0 - 2016-05-22

* Fix bug when mediator would refuse to work with custom types.
* Use phobos-style import syntax.

## 1.5.0 - 2016-05-22

* Avoid generating dynamic method names in the event machines.

## 1.4.2 - 2016-05-19

* Use template methods for event machines.

## 1.4.1 - 2016-05-19

* Reimplement the mediator.

## 1.4.0 - 2016-05-18

* Implement a range interface.

## 1.3.0 - 2016-05-17

* Add a mediator.
* Add an external dependency to fill in `std.experimental.allocator`.

## 1.2.3 - 2016-01-05

* Add `beforeEach` and `afterEach` hooks.

## 1.2.2 - 2016-01-04

* Make `Event.append` and `Event.prepend` variadic.

## 1.2.1 - 2016-01-04

* Dynamically bind event machine state.

## 1.2.0 - 2016-01-03

* Use delegates by default.
* Implement event machines.
* Add documentation.
* Remove pubsub component.

## 1.1.1 - 2015-07-05

* Fix bug in callable counter.

## 1.1.0 - 2015-07-04

* Use compile-time channel creation.

## 1.0.1 - 2015-07-03

* Add pop and shift operations.

## 1.0.0 - 2015-06-29

* Initial release.
