# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2025-12-20

### Changed

- **BREAKING**: Complete API redesign with block-based Trail object
- `breadcrumbs` now uses a block that receives a `Trail` object
- Breadcrumb blocks are evaluated lazily on first access (after `before_action` callbacks)
- `only:` and `except:` options now apply to blocks (like `before_action`)

### Added

- `Trail` class with manipulation methods:
  - `add`, `prepend`, `insert_after`, `insert_before`, `remove`, `replace`, `clear`
  - `find`, `include?`, `size`, `empty?`, `each`, `first`, `last`
- View helpers:
  - `breadcrumb_trail` yields each crumb or returns array
  - `breadcrumb_names` returns array of names
  - `breadcrumb_title(separator:, reverse:)` for `<title>` tag
  - `breadcrumb_json_ld(base_url:)` for SEO structured data
- Test helpers:
  - RSpec: `have_breadcrumb`, `have_breadcrumbs` matchers
  - Minitest: `assert_breadcrumb`, `assert_breadcrumbs`, `refute_breadcrumb`, `refute_breadcrumbs`
- Action-level trail manipulation via `breadcrumbs.add`, `breadcrumbs.clear`, etc.
- Block syntax in actions: `breadcrumbs { |trail| trail.add ... }`

### Removed

- `breadcrumb(name, path, options)` declarative DSL (replaced by block API)
- `breadcrumb_group` helper (use conditionals in blocks)
- `render_breadcrumbs` helper (use `breadcrumb_trail` with custom markup)

### Migration

Before (v1.x):
```ruby
class ArticlesController < ApplicationController
  breadcrumb "Articles", :articles_path
  breadcrumb -> { @article.title }, only: [:show, :edit]
end
```

After (v2.0):
```ruby
class ArticlesController < ApplicationController
  breadcrumbs do |trail|
    trail.add "Articles", articles_path
  end

  breadcrumbs only: %i[show edit] do |trail|
    trail.add @article.title
  end
end
```

## [1.1.0] - 2025-12-10

### Added

- `breadcrumb_group` to apply shared `only:`/`except:` filters to multiple breadcrumbs
- Conditional `clear_breadcrumbs` with `only:` and `except:` options
- Nested groups with intelligent option merging (intersection for `:only`, union for `:except`)

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

[Unreleased]: https://github.com/Sbastien/petit_poucet/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/Sbastien/petit_poucet/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/Sbastien/petit_poucet/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Sbastien/petit_poucet/releases/tag/v1.0.0
