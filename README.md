# Petit Poucet

[![gem version](https://img.shields.io/gem/v/petit_poucet.svg)](https://rubygems.org/gems/petit_poucet)
[![gem downloads](https://img.shields.io/gem/dt/petit_poucet.svg)](https://rubygems.org/gems/petit_poucet)
[![ci](https://img.shields.io/github/actions/workflow/status/Sbastien/petit_poucet/ci.yml?branch=main&label=ci)](https://github.com/Sbastien/petit_poucet/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)](https://github.com/Sbastien/petit_poucet)
[![license](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-red.svg)](https://www.ruby-lang.org/)
[![rails](https://img.shields.io/badge/rails-%3E%3D%207.0-red.svg)](https://rubyonrails.org/)

***Breadcrumbs for Rails, the simple way.***

A lightweight breadcrumbs gem for Ruby on Rails: block-based API, controller inheritance, default partial, and full view customization.

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Installation](#installation)
- [Defining Breadcrumbs](#defining-breadcrumbs)
  - [In Controllers](#in-controllers)
  - [Dynamic breadcrumbs in actions](#dynamic-breadcrumbs-in-actions)
  - [Inheritance](#inheritance)
- [Rendering](#rendering)
  - [Default Partial](#default-partial)
  - [ViewComponent](#viewcomponent)
  - [Phlex](#phlex)
  - [Custom Markup](#custom-markup)
  - [Page Title](#page-title)
  - [JSON-LD for SEO](#json-ld-for-seo)
- [Testing](#testing)
- [API Reference](#api-reference)
- [Upgrading from v1.x](#upgrading-from-v1x)
- [Requirements](#requirements)
- [Type Signatures](#type-signatures)

## Quick Start

```ruby
# Gemfile
gem "petit_poucet", "~> 2.0"
```

```bash
$ bundle install
$ rails generate petit_poucet:install
```

The generator copies the partial to `app/views/petit_poucet/_breadcrumbs.html.erb` and prints next steps.

```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  breadcrumbs "Articles", :articles_path

  def show
    @article = Article.find(params[:id])
    breadcrumbs.add @article.title
  end
end
```

```erb
<%# app/views/layouts/application.html.erb %>
<%= render "petit_poucet/breadcrumbs" %>
```

That's it. You get an ARIA-compliant `<nav>` with your breadcrumbs.

## Features

- **Declarative class-level API**: `breadcrumbs "Name", :path` registered as a `before_action`
- **Runtime mutation**: `breadcrumbs.add`, `.insert_before`, `.replace`, `.clear` from any action
- **Rich collection class**: manipulation methods (`insert_after`, `find_by_name`, `exists?`, ...) and `Enumerable`
- **Controller inheritance**: child controllers inherit parent breadcrumbs
- **Default partial**: ARIA-compliant out of the box, override with a generator
- **SEO ready**: JSON-LD structured data helper
- **Test helpers**: RSpec matchers and Minitest assertions included
- **Thin layer over Rails**: uses `before_action` under the hood, no custom callback machinery

## Installation

```ruby
gem "petit_poucet", "~> 2.0"
```

```bash
bundle install
```

The gem auto-loads into `ActionController::Base` and `ActionView::Base` via a Railtie. No initializer required.

## Defining Breadcrumbs

### In Controllers

Declare static breadcrumbs at the class level. Each call registers a `before_action`:

```ruby
class ArticlesController < ApplicationController
  breadcrumbs "Articles", :articles_path
  breadcrumbs "Admin",   :admin_path,    only: :admin_section
  breadcrumbs "Premium", :premium_path,  if: -> { current_user&.premium? }
end
```

The path can be:

- A **String**: used verbatim as the URL
- A **Symbol**: sent to the controller (e.g. `:root_path` calls `root_path`)
- A **Proc**: evaluated in the controller context (e.g. `-> { article_path(@article) }`)
- `nil`: for the current page (no link in the default partial)

Filter options (`only:`, `except:`, `if:`, `unless:`) pass through to `before_action`.

### Dynamic breadcrumbs in actions

For breadcrumbs that depend on instance variables, mutate the collection from inside the action:

```ruby
class ArticlesController < ApplicationController
  breadcrumbs "Articles", :articles_path

  def show
    @article = Article.find(params[:id])
    breadcrumbs.add @article.title, article_path(@article)
  end
end
```

You can also use a block to group multiple mutations:

```ruby
def show
  @article = Article.find(params[:id])

  breadcrumbs do |crumbs|
    crumbs.add @article.section.name, section_path(@article.section)
    crumbs.add @article.title, article_path(@article)
  end
end
```

For breadcrumbs shared across multiple actions, extract a `before_action` helper:

```ruby
class ArticlesController < ApplicationController
  before_action :set_article,             only: %i[show edit]
  before_action :add_article_breadcrumb,  only: %i[show edit]

  private

  def set_article = @article = Article.find(params[:id])
  def add_article_breadcrumb = breadcrumbs.add @article.title, article_path(@article)
end
```

### Inheritance

Child controllers inherit parent declarations and add their own on top:

```ruby
class ApplicationController < ActionController::Base
  breadcrumbs "Home", :root_path
end

class ArticlesController < ApplicationController
  breadcrumbs "Articles", :articles_path
end
# Result: Home / Articles
```

To start fresh in a namespace (e.g. admin), clear at runtime:

```ruby
class AdminController < ApplicationController
  before_action :reset_breadcrumbs

  private
  def reset_breadcrumbs
    breadcrumbs.clear
    breadcrumbs.add "Admin", admin_root_path
  end
end
```

## Rendering

### Default Partial

The gem ships an ARIA-compliant partial. Render it anywhere:

```erb
<%= render "petit_poucet/breadcrumbs" %>
```

To customize the markup, copy the partial into your app:

```bash
rails generate petit_poucet:views
# create  app/views/petit_poucet/_breadcrumbs.html.erb
```

To translate the `aria-label` for a non-English app, set the `petit_poucet.aria_label` key in your locale file:

```yaml
# config/locales/fr.yml
fr:
  petit_poucet:
    aria_label: "Fil d'Ariane"
```

### Themes

The install/views generators ship Tailwind and Bootstrap variants:

```bash
rails generate petit_poucet:install --theme=tailwind
rails generate petit_poucet:install --theme=bootstrap
```

The default theme uses minimal, neutral classes. Themed variants are starting points: copy them and edit freely.

### ViewComponent

If your app uses [ViewComponent](https://viewcomponent.org), render via the bundled component:

```erb
<%= render(PetitPoucet::BreadcrumbsComponent.new) %>
```

The component reads from `helpers.breadcrumbs` by default. Pass an explicit `crumbs:` argument to override:

```erb
<%= render(PetitPoucet::BreadcrumbsComponent.new(crumbs: my_breadcrumbs)) %>
```

The component is loaded only when `ViewComponent::Base` is defined, so apps that don't use ViewComponent are unaffected.

### Phlex

If your app uses [Phlex](https://www.phlex.fun), render the bundled component:

```ruby
class ArticlePage < Phlex::HTML
  def view_template
    render(PetitPoucet::PhlexBreadcrumbs.new(crumbs: helpers.breadcrumbs))
    # ... rest of the page
  end
end
```

The collection is passed explicitly because Phlex components don't have implicit access to controller helpers.

### Custom Markup

For full control, iterate with `each_breadcrumb`. Each crumb exposes `name`, `path`, and `current?`:

```erb
<nav aria-label="Breadcrumb">
  <ol>
    <% each_breadcrumb do |crumb| %>
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

### Page Title

```erb
<title><%= breadcrumb_title(reverse: true) %></title>
<%# => "My Article | Articles | Home" %>
```

Customize separator and order:

```erb
<%= breadcrumb_title(separator: " · ", reverse: false) %>
```

### JSON-LD for SEO

```erb
<%= breadcrumb_json_ld %>
```

Outputs a `<script type="application/ld+json">` tag with [schema.org BreadcrumbList](https://schema.org/BreadcrumbList) data, ready for Google rich results. Pass `base_url:` to make relative paths absolute:

```erb
<%= breadcrumb_json_ld(base_url: "https://example.com") %>
```

## Testing

### RSpec

```ruby
# spec/rails_helper.rb
require "petit_poucet/test_helpers"

RSpec.configure do |config|
  config.include PetitPoucet::TestHelpers, type: :controller
  config.include PetitPoucet::TestHelpers, type: :request
end
```

```ruby
it "shows article breadcrumbs" do
  get article_path(article)

  expect(controller).to have_breadcrumb("Articles")
  expect(controller).to have_breadcrumbs(["Home", "Articles", "My Article"])
end
```

### Minitest

```ruby
# test/test_helper.rb
require "petit_poucet/test_helpers"

class ActionDispatch::IntegrationTest
  include PetitPoucet::TestHelpers
end
```

```ruby
test "shows article breadcrumbs" do
  get article_path(article)

  assert_breadcrumb "Articles"
  assert_breadcrumbs ["Home", "Articles", "My Article"]
  refute_breadcrumb "Admin"
end
```

## API Reference

### Block Methods

Inside a `breadcrumbs` block, the yielded object exposes:

| Method                               | Description                          |
| ------------------------------------ | ------------------------------------ |
| `add(name, path = nil)`              | Append breadcrumb to end             |
| `prepend(name, path = nil)`          | Insert breadcrumb at beginning       |
| `insert_after(target, name, path)`   | Insert after named breadcrumb        |
| `insert_before(target, name, path)`  | Insert before named breadcrumb       |
| `replace(target, name, path)`        | Replace breadcrumb by name           |
| `remove(name)`                       | Remove breadcrumb by name            |
| `find_by_name(name)`                 | Find breadcrumb by name              |
| `exists?(name)`                      | Check if breadcrumb exists           |
| `clear`                              | Remove all breadcrumbs               |
| `size`, `empty?`, `each`, `map`, ... | Standard `Enumerable` methods        |

### View Helpers

| Helper                                     | Returns                                                     |
| ------------------------------------------ | ----------------------------------------------------------- |
| `each_breadcrumb`                          | Yields each crumb (`name`, `path`, `current?`), or array    |
| `breadcrumb_names`                         | Array of names, e.g. `["Home", "Articles"]`                 |
| `current_breadcrumb`                       | The last `Breadcrumb` (the current page), or `nil`          |
| `breadcrumb_title(separator:, reverse:)`   | Joined string for `<title>` tag                             |
| `breadcrumb_json_ld(base_url:)`            | `<script>` tag with schema.org BreadcrumbList JSON-LD       |

## Instrumentation

Petit Poucet emits an `ActiveSupport::Notifications` event each time `each_breadcrumb` is invoked:

```ruby
ActiveSupport::Notifications.subscribe('petit_poucet.render') do |*, payload|
  Rails.logger.debug("Rendered #{payload[:size]} breadcrumbs")
end
```

The payload includes `:size`, the number of breadcrumbs in the collection.

## Upgrading from v1.x

For most controllers, migration is renaming `breadcrumb` (singular) to `breadcrumbs` (plural):

```ruby
# v1.x
breadcrumb "Articles", :articles_path

# v2.0
breadcrumbs "Articles", :articles_path
```

Lambdas as path arguments still work (now in positional form):

```ruby
# v1.x
breadcrumb -> { @article.title }, only: :show

# v2.0, mutate from the action
def show
  @article = Article.find(params[:id])
  breadcrumbs.add @article.title, article_path(@article)
end
```

Removed helpers (`breadcrumb_group`, `render_breadcrumbs`, `clear_breadcrumbs`) and their replacements are documented in [CHANGELOG](CHANGELOG.md).

## Requirements

- Ruby >= 3.2
- Rails >= 7.0

## Type Signatures

RBS signatures for the public API are bundled in `sig/petit_poucet.rbs`. Apps using Steep or TypeProf get autocomplete and type checking out of the box.

## License

MIT

---

## About the Name

> *Le petit Pouçet les laissoit crier, sçachant bien par où il reviendroit à la maison ; car en marchant il avoit laissé tomber le long du chemin les petits cailloux blancs qu'il avoit dans ses poches.*
>
> Charles Perrault, *Le Petit Poucet* (1697)

Named after the French fairy tale "Le Petit Poucet" (Hop-o'-My-Thumb), where a clever boy leaves pebbles along the way to find his way home.
