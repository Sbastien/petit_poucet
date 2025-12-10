# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `breadcrumb_group` to apply shared `only:`/`except:` filters to multiple breadcrumbs
- Conditional `clear_breadcrumbs` with `only:` and `except:` options
- Nested groups with intelligent option merging (intersection for `:only`, union for `:except`)
- `breadcrumb_json_ld` view helper for SEO structured data (schema.org BreadcrumbList)

## [1.0.0] - 2025-12-03

### Added

- Declarative `breadcrumb` DSL for controllers (class and instance level)
- Action filtering with `only:` and `except:` options
- Dynamic breadcrumbs with lambdas and symbols
- `breadcrumb_trail` view helper with `CrumbPresenter`
- `current?` method to identify the last breadcrumb
- `render_breadcrumbs` simple view helper with customizable separator and class
- `clear_breadcrumbs` to reset inherited breadcrumbs
- Rails 7.0+ and Ruby 3.0+ support
