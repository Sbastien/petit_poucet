# Petit Poucet

[![gem version](https://img.shields.io/gem/v/petit_poucet.svg)](https://rubygems.org/gems/petit_poucet)
[![gem downloads](https://img.shields.io/gem/dt/petit_poucet.svg)](https://rubygems.org/gems/petit_poucet)
[![ci](https://img.shields.io/github/actions/workflow/status/Sbastien/petit_poucet/ci.yml?branch=main&label=ci)](https://github.com/Sbastien/petit_poucet/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)](https://github.com/Sbastien/petit_poucet)
[![license](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-red.svg)](https://www.ruby-lang.org/)
[![rails](https://img.shields.io/badge/rails-%3E%3D%207.0-red.svg)](https://rubyonrails.org/)

***Breadcrumbs for Rails, the simple way.***

A lightweight, zero-dependency breadcrumbs gem for Ruby on Rails. Simple block-based API, controller inheritance, and full view customization.

## Features

- **Zero dependencies** — only Rails required
- **Block-based API** — flexible breadcrumb building with a Trail object
- **Controller inheritance** — child controllers inherit parent breadcrumbs
- **Flexible rendering** — built-in helpers or full custom views
- **Lazy evaluation** — blocks evaluated after `before_action` callbacks
- **SEO ready** — JSON-LD structured data helper

## Installation

```ruby
gem "petit_poucet", "~> 2.0"
```

## Usage

### Controller

```ruby
class ApplicationController < ActionController::Base
  breadcrumbs do |trail|
    trail.add t("home"), root_path
  end
end

class ArticlesController < ApplicationController
  breadcrumbs do |trail|
    trail.add "Articles", articles_path
    trail.add @article.title, article_path(@article) if @article
    trail.add "Edit" if action_name.in?(%w[edit update])
  end

  def show
    @article = Article.find(params[:id])
  end

  def edit
    @article = Article.find(params[:id])
  end
end
```

### Trail Methods

The trail object provides methods to build and manipulate breadcrumbs:

```ruby
breadcrumbs do |trail|
  trail.add "Name", "/path"        # Append to end
  trail.prepend "First", "/first"  # Insert at beginning
  trail.clear                      # Remove all breadcrumbs
end
```

| Method | Description |
|--------|-------------|
| `add(name, path = nil)` | Append breadcrumb to end |
| `prepend(name, path = nil)` | Insert breadcrumb at beginning |
| `insert_after(target, name, path)` | Insert after named breadcrumb |
| `insert_before(target, name, path)` | Insert before named breadcrumb |
| `replace(target, name, path)` | Replace breadcrumb by name |
| `remove(name)` | Remove breadcrumb by name |
| `find(name)` | Find breadcrumb by name |
| `include?(name)` | Check if breadcrumb exists |
| `clear` | Remove all breadcrumbs |
| `size`, `empty?`, `each`, `first`, `last` | Enumerable methods |

### Action-Level Manipulation

You can also manipulate breadcrumbs within controller actions:

```ruby
def preview
  @article = Article.find(params[:id])

  # Direct calls
  breadcrumbs.clear
  breadcrumbs.add "Preview", preview_path

  # Or block syntax (same result)
  breadcrumbs do |trail|
    trail.clear
    trail.add "Preview", preview_path
  end
end
```

### Action Filtering

Use `only:` and `except:` options to filter blocks by action (like `before_action`):

```ruby
breadcrumbs do |trail|
  trail.add "Articles", articles_path
end

breadcrumbs only: %i[show edit update] do |trail|
  trail.add @article.title, article_path(@article)
end

breadcrumbs only: %i[edit update] do |trail|
  trail.add "Edit"
end

breadcrumbs except: :index do |trail|
  trail.add "Details"
end
```

### Conditional Breadcrumbs

You can also use Ruby conditionals inside blocks:

```ruby
breadcrumbs do |trail|
  trail.add "Articles", articles_path

  # Skip entirely for some actions
  next if action_name == "index"

  # Conditional breadcrumbs
  trail.add @article.title if @article
  trail.add @article.category.name if @article&.category
end
```

### View Rendering

Use `breadcrumb_trail` to iterate over breadcrumbs. Each crumb has `name`, `path`, and `current?`:

```erb
<nav aria-label="Breadcrumb">
  <ol>
    <% breadcrumb_trail do |crumb| %>
      <li>
        <% if crumb.current? %>
          <%= crumb.name %>
        <% else %>
          <%= link_to crumb.name, crumb.path %>
        <% end %>
      </li>
    <% end %>
  </ol>
</nav>
```

#### Page Title

```erb
<title><%= breadcrumb_title(reverse: true) %></title>
<%# => "My Article | Articles | Home" %>
```

#### JSON-LD for SEO

```erb
<%= breadcrumb_json_ld %>
<%# => <script type="application/ld+json">{"@context":"https://schema.org",...}</script> %>
```

### View Helpers

| Helper | Description |
|--------|-------------|
| `breadcrumb_trail` | Yields each crumb, or returns array of CrumbPresenter |
| `breadcrumb_names` | Returns `["Home", "Articles"]` |
| `breadcrumb_title(separator:, reverse:)` | Returns string for `<title>` tag |
| `breadcrumb_json_ld(base_url:)` | Returns JSON-LD script tag for SEO |

### CrumbPresenter

| Method | Description |
|--------|-------------|
| `name` | Display text |
| `path` | URL (can be nil) |
| `current?` | `true` if last breadcrumb |

### Clearing Breadcrumbs

#### `clear_breadcrumbs` (class level)

Prevents inherited blocks from running. Parent blocks are **never executed**:

```ruby
class AdminController < ApplicationController
  clear_breadcrumbs  # ApplicationController blocks won't run at all

  breadcrumbs do |trail|
    trail.add "Admin", admin_root_path
  end
end
```

#### `trail.clear` / `breadcrumbs.clear`

Clears the trail after parent blocks have run. Use in a block or in an action:

```ruby
# In a block
breadcrumbs do |trail|
  trail.clear if action_name == "standalone"
  trail.add "Standalone Page"
end

# In an action
def preview
  breadcrumbs.clear
  breadcrumbs.add "Preview", preview_path
end
```

#### When to use which?

| Method | Parent blocks run? | Use case |
|--------|-------------------|----------|
| `clear_breadcrumbs` | No | Controller with completely separate hierarchy |
| `trail.clear` | Yes | Conditional clearing based on action/state |

### Test Helpers

#### RSpec

Add to your `spec_helper.rb` or `rails_helper.rb`:

```ruby
require "petit_poucet/test_helpers"

RSpec.configure do |config|
  config.include PetitPoucet::TestHelpers, type: :controller
  config.include PetitPoucet::TestHelpers, type: :request
end
```

Then in your specs:

```ruby
it "shows article breadcrumbs" do
  get article_path(article)

  expect(controller).to have_breadcrumb("Articles")
  expect(controller).to have_breadcrumbs(["Home", "Articles", "My Article"])
end
```

#### Minitest

Add to your `test_helper.rb`:

```ruby
require "petit_poucet/test_helpers"

class ActionDispatch::IntegrationTest
  include PetitPoucet::TestHelpers
end
```

Then in your tests:

```ruby
test "shows article breadcrumbs" do
  get article_path(article)

  assert_breadcrumb "Articles"
  assert_breadcrumbs ["Home", "Articles", "My Article"]
  refute_breadcrumb "Admin"
end
```

## Complete Example

```ruby
class ArticlesController < ApplicationController
  before_action :set_article, only: %i[show edit]

  breadcrumbs do |trail|
    trail.add "Articles", articles_path
    trail.add @article.title, article_path(@article) if @article
  end

  def edit
    breadcrumbs.add "Edit"
  end
end
```

| Action | Breadcrumbs                  |
|--------|------------------------------|
| index  | Articles                     |
| show   | Articles / My Article        |
| edit   | Articles / My Article / Edit |

## Requirements

- Ruby >= 3.2
- Rails >= 7.0

## License

MIT

---

## About the Name

> *Le petit Pouçet les laissoit crier, sçachant bien par où il reviendroit à la maison ; car en marchant il avoit laissé tomber le long du chemin les petits cailloux blancs qu'il avoit dans ses poches.*
>
> — Charles Perrault, *Le Petit Poucet* (1697)

Named after the French fairy tale "Le Petit Poucet" (Hop-o'-My-Thumb), where a clever boy leaves a trail of pebbles to find his way home.
