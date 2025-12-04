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

## Code Style

```bash
bundle exec rubocop
```

## Pull Request Process

1. Create a feature branch from `main`
2. Write tests for new functionality
3. Ensure all tests pass
4. Update CHANGELOG.md
5. Submit PR with clear description

## Gem Structure

```text
lib/
├── petit_poucet.rb           # Main entry point
└── petit_poucet/
    ├── controller_methods.rb  # DSL for controllers
    ├── crumb.rb              # Breadcrumb data object
    ├── crumb_presenter.rb    # View presenter
    ├── railtie.rb            # Rails integration
    ├── version.rb            # Version constant
    └── view_helpers.rb       # View helpers
```

## Adding Features

- Keep the API minimal
- No HTML opinions - let users control rendering
- Support lambdas and symbols for dynamic values
- Write specs for all new functionality
