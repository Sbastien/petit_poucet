# Petit Poucet 🥖

[![gem version](https://img.shields.io/gem/v/petit_poucet.svg)](https://rubygems.org/gems/petit_poucet)
[![gem downloads](https://img.shields.io/gem/dt/petit_poucet.svg)](https://rubygems.org/gems/petit_poucet)
[![ci](https://img.shields.io/github/actions/workflow/status/Sbastien/petit_poucet/ci.yml?branch=main&label=ci)](https://github.com/Sbastien/petit_poucet/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0-red.svg)](https://www.ruby-lang.org/)
[![rails](https://img.shields.io/badge/rails-%3E%3D%207.0-red.svg)](https://rubyonrails.org/)

***Breadcrumbs for Rails, the simple way.***

A lightweight, zero-dependency breadcrumbs gem for Ruby on Rails. Simple DSL, controller inheritance, and full view customization — help your users find their way back, one pebble at a time.

## Features

- 🪶 **Zero dependencies** — only Rails required
- 🎯 **Simple DSL** — declare breadcrumbs in one line
- 🔗 **Controller inheritance** — child controllers inherit parent breadcrumbs
- 🎨 **Flexible rendering** — use the built-in helper or full custom views
- ⚡ **Lazy evaluation** — lambdas for dynamic names and paths
- 🎛️ **Action filtering** — `only` and `except` options for fine control
- 📦 **Grouping** — apply filters to multiple breadcrumbs at once

## Installation

```ruby
gem "petit_poucet"
```

## Usage

### Controller

```ruby
class ApplicationController < ActionController::Base
  breadcrumb -> { t("home") }, :root_path
end

class ArticlesController < ApplicationController
  breadcrumb "Articles", :articles_path
  breadcrumb -> { @article.title }, only: [:show, :edit, :update]

  def show
    @article = Article.find(params[:id])
  end
end
```

### DSL Options

```ruby
# Static
breadcrumb "Dashboard", :dashboard_path

# Dynamic name
breadcrumb -> { t("breadcrumbs.home") }, :root_path

# Dynamic path
breadcrumb "Profile", -> { user_path(current_user) }

# Action filtering
breadcrumb "Edit", :edit_article_path, only: [:edit, :update]
breadcrumb "Details", :articles_path, except: :index

# Action filtering without path
breadcrumb "Current", only: :show

# No link (current page)
breadcrumb -> { @article.title }
```

### Runtime Breadcrumbs

You can also add breadcrumbs at runtime in actions or `before_action` callbacks:

```ruby
def show
  @article = Article.find(params[:id])
  breadcrumb @article.title, article_path(@article)
  breadcrumb "Details"  # No link
end
```

#### Combining Declarative and Runtime

Use declarative breadcrumbs for general structure and runtime for action-specific additions:

```ruby
class ArticlesController < ApplicationController
  breadcrumb "Articles", :articles_path

  def show
    @article = Article.find(params[:id])
    breadcrumb @article.title, article_path(@article)
    breadcrumb @article.category.name, category_path(@article.category) if @article.category
  end

  def edit
    @article = Article.find(params[:id])
    breadcrumb @article.title, article_path(@article)
    breadcrumb "Edit"
  end
end
# show → Articles → My Article → Tech (if category exists)
# edit → Articles → My Article → Edit
```

### View Rendering

#### Simple (built-in helper)

```erb
<%= render_breadcrumbs %>
<%# => <nav class="breadcrumb"><a href="/">Home</a> / Articles / My Article</nav> %>

<%= render_breadcrumbs(class: "my-breadcrumb", separator: " > ") %>
```

#### Custom (full control)

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

### CrumbPresenter

| Method     | Description              |
|------------|--------------------------|
| `name`     | Display text             |
| `path`     | URL (can be nil)         |
| `current?` | `true` if last breadcrumb |
| `to_s`     | Returns `name`           |

### Clearing Inherited Breadcrumbs

```ruby
class AdminController < ApplicationController
  clear_breadcrumbs
  breadcrumb "Admin", :admin_root_path
end
```

#### Conditional Clearing

Clear inherited breadcrumbs only for specific actions:

```ruby
class Admin::ArticlesController < AdminController
  # Start fresh on :new and :create actions only
  clear_breadcrumbs only: %i[new create]
  breadcrumb "New Article", only: %i[new create]
end

class PublicController < ApplicationController
  # Clear inherited breadcrumbs on all actions except :index
  clear_breadcrumbs except: :index
  breadcrumb "Public Section"
end
```

### Grouping Breadcrumbs

Use `breadcrumb_group` to apply the same `only`/`except` filters to multiple breadcrumbs:

```ruby
class ArticlesController < ApplicationController
  # These breadcrumbs only appear on :edit and :update
  breadcrumb_group only: %i[edit update] do
    breadcrumb "Articles", :articles_path
    breadcrumb -> { @article.title }, -> { article_path(@article) }
    breadcrumb "Edit"
  end
end
```

#### Nested Groups

Groups can be nested. Options are merged intelligently:

- `:only` uses **intersection** (more restrictive)
- `:except` uses **union** (cumulative exclusions)

```ruby
class ArticlesController < ApplicationController
  breadcrumb_group except: :index do
    breadcrumb "Articles", :articles_path

    breadcrumb_group only: %i[edit update] do
      # Appears on :edit and :update, but NOT on :index
      breadcrumb -> { @article.title }, -> { article_path(@article) }
    end
  end
end
```

#### Overriding Group Options

Individual breadcrumbs can override group options:

```ruby
breadcrumb_group only: %i[show edit update] do
  breadcrumb "Details", :article_path      # Appears on :show, :edit, :update
  breadcrumb "Edit Form", only: :edit      # Appears only on :edit (intersection)
end
```

#### Combining Groups with Regular Breadcrumbs

```ruby
class ArticlesController < ApplicationController
  breadcrumb "Home", :root_path                          # Always

  breadcrumb_group only: %i[edit update] do
    breadcrumb "Edit Section", :edit_article_path        # Only on :edit, :update
  end

  breadcrumb -> { @article.title }, except: :index       # Except :index
end
```

### Complete Example

A typical CRUD controller setup:

```ruby
class ArticlesController < ApplicationController
  breadcrumb "Articles", :articles_path

  # Show article title on :show, :edit, :update, :destroy
  breadcrumb_group only: %i[show edit update destroy] do
    breadcrumb -> { @article.title }, -> { article_path(@article) }
  end

  # Add "Edit" crumb on :edit and :update
  breadcrumb "Edit", only: %i[edit update]

  # Different breadcrumb for new articles
  breadcrumb "New Article", only: %i[new create]

  def show
    @article = Article.find(params[:id])
  end

  # ...
end
```

**Result:**

| Action   | Breadcrumbs                          |
|----------|--------------------------------------|
| index    | Articles                             |
| show     | Articles / My Article                |
| edit     | Articles / My Article / Edit         |
| new      | Articles / New Article               |

## API Reference

### Controller Class Methods

| Method | Description |
|--------|-------------|
| `breadcrumb(name, path = nil, **options)` | Declare a breadcrumb |
| `clear_breadcrumbs(**options)` | Clear inherited breadcrumbs |
| `breadcrumb_group(**options, &block)` | Group breadcrumbs with shared options |

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `:only` | Show only on these actions | `only: %i[edit update]` |
| `:except` | Show on all actions except these | `except: :index` |

### Dynamic Values

| Type | Name | Path |
|------|------|------|
| String | `"Home"` | `"/path"` |
| Symbol | `:method_name` | `:path_helper` |
| Proc | `-> { @model.title }` | `-> { model_path(@model) }` |

## Requirements

- Ruby >= 3.0
- Rails >= 7.0

## License

MIT

---

## About the Name

> *Le petit Pouçet les laissoit crier, sçachant bien par où il reviendroit à la maison ; car en marchant il avoit laissé tomber le long du chemin les petits cailloux blancs qu'il avoit dans ses poches.*
>
> — Charles Perrault, *Le Petit Poucet* (1697)

Named after the French fairy tale "Le Petit Poucet" (Hop-o'-My-Thumb), where a clever boy leaves a trail of pebbles to find his way home.
