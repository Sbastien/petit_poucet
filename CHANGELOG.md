# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-05-08

### Changed

- **BREAKING**: Complete API redesign. Class-level declarations register `before_action`s.
- `breadcrumbs "Name", :path`, single positional form for static crumbs
- Path may be a String (verbatim), a Symbol (sent to controller), or a Proc (instance_exec'd)
- Filter options (`only:`, `except:`, `if:`, `unless:`) pass through to `before_action`
- Dynamic crumbs are added imperatively from inside actions via `breadcrumbs.add`

### Added

- `Breadcrumb` immutable value object (validated, frozen)
- `Breadcrumbs` collection class with manipulation methods:
  - `add`, `prepend`, `insert_after`, `insert_before`, `remove`, `replace`, `clear`
  - `find_by_name`, `exists?`, `names`, `size`, `empty?`, `[]`, `last`, `to_a`
  - Full `Enumerable` support (`each`, `map`, `select`, `find`, ...)
- View helpers:
  - `each_breadcrumb` yields each crumb or returns array
  - `breadcrumb_names` returns array of names
  - `current_breadcrumb` returns the last (current) breadcrumb, or nil
  - `breadcrumb_title(separator:, reverse:)` for `<title>` tag
  - `breadcrumb_json_ld(base_url:)` for SEO structured data
- Default partial `petit_poucet/breadcrumbs` with ARIA-compliant markup (`aria-label` driven by I18n key `petit_poucet.aria_label`)
- Generators:
  - `rails generate petit_poucet:install`, friendly entry point with next-step instructions
  - `rails generate petit_poucet:views`, copy the partial for customization
  - Both accept `--theme=tailwind|bootstrap|default` for ready-made styled variants
- Test helpers:
  - RSpec: `have_breadcrumb`, `have_breadcrumbs` matchers
  - Minitest: `assert_breadcrumb`, `assert_breadcrumbs`, `refute_breadcrumb`, `refute_breadcrumbs`
  - Capybara matchers (opt-in via `require 'petit_poucet/capybara_matchers'`): `have_breadcrumb_text`, `have_breadcrumb_list` for system/feature specs
- Block syntax in actions for grouped runtime mutations: `breadcrumbs { |crumbs| crumbs.add ... }`
- Optional `PetitPoucet::BreadcrumbsComponent` (loaded when ViewComponent is available)
- Optional `PetitPoucet::PhlexBreadcrumbs` (loaded when Phlex is available)
- `ActiveSupport::Notifications.instrument('petit_poucet.render', size:)` event on every `each_breadcrumb` invocation
- RBS type signatures bundled in `sig/petit_poucet.rbs` for Steep/TypeProf users
- Rails 8 compatibility (CI matrix covers Rails 7.0/7.1/8.0)

### Removed

- `breadcrumb(name, path, options)` declarative DSL, replaced by block API
- `breadcrumb_group` helper, use a single block with conditionals, or multiple `breadcrumbs only:` / `except:` blocks
- `render_breadcrumbs` view helper, use `each_breadcrumb do |crumb| ... end` with your own ERB markup
- `clear_breadcrumbs` (and its `only:`/`except:` options), use `crumbs.clear` inside a `breadcrumbs` block instead
- Lambda / symbol arguments to individual breadcrumbs, use plain Ruby inside the block instead

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
  breadcrumbs do |crumbs|
    crumbs.add "Articles", articles_path
  end

  breadcrumbs only: %i[show edit] do |crumbs|
    crumbs.add @article.title
  end
end
```

#### Removed helpers and replacements

- `breadcrumb_group(only:) { ... }` → multiple `breadcrumbs only:` blocks, or one block with `if` / `next`
- `render_breadcrumbs` → iterate `each_breadcrumb` in ERB with your own markup
- `clear_breadcrumbs` → `breadcrumbs do |crumbs| crumbs.clear; crumbs.add ... end`
- `breadcrumb -> { @x.title }` → `breadcrumbs do |crumbs| crumbs.add @x.title end` (blocks are lazy by design)

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
- `breadcrumb_trail` view helper (now `each_breadcrumb`) with `CrumbPresenter`
- `current?` method to identify the last breadcrumb
- `render_breadcrumbs` simple view helper with customizable separator and class
- `clear_breadcrumbs` to reset inherited breadcrumbs
- Rails 7.0+ and Ruby 3.0+ support

[Unreleased]: https://github.com/Sbastien/petit_poucet/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/Sbastien/petit_poucet/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/Sbastien/petit_poucet/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Sbastien/petit_poucet/releases/tag/v1.0.0
