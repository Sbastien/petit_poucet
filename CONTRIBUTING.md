# Contributing to Petit Poucet

## Development Setup

```bash
git clone https://github.com/Sbastien/petit_poucet.git
cd petit_poucet
bundle install
bundle exec rspec
```

## Running Tests

```bash
bundle exec rspec
```

Tests generate a coverage report in `coverage/`. Open `coverage/index.html` to view detailed coverage.

## Code Style

```bash
bundle exec rubocop
```

## Pull Request Process

1. Create a feature branch from `main`
2. Write tests for new functionality
3. Ensure all tests pass and coverage remains above 95%
4. Update CHANGELOG.md
5. Submit PR with clear description

## Gem Structure

```text
lib/
├── petit_poucet.rb           # Main entry point, requires all modules
└── petit_poucet/
    ├── version.rb            # Version constant
    ├── crumb.rb              # Immutable breadcrumb data object (Data.define)
    ├── trail.rb              # Core Trail collection class
    ├── crumb_presenter.rb    # View presenter wrapping crumbs
    ├── controller.rb         # Rails controller integration (Concern)
    ├── view_helpers.rb       # View helpers (render, title, JSON-LD)
    ├── railtie.rb            # Rails initialization
    └── test_helpers.rb       # RSpec matchers for testing
```

## Key Concepts

- **Trail**: Pure Ruby collection class, no Rails dependencies
- **Crumb**: Immutable value object using Ruby 3.2+ `Data.define`
- **Lazy evaluation**: Breadcrumb blocks execute after `before_action` callbacks
- **Block inheritance**: Child controllers inherit parent breadcrumb blocks

## Adding Features

- Keep the API minimal
- No HTML opinions - let users control rendering
- Use blocks for dynamic values (evaluated lazily)
- Write specs for all new functionality
- Maintain 95%+ code coverage
