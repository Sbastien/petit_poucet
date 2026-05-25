# frozen_string_literal: true

require 'spec_helper'
require 'action_view'
require 'action_controller'

RSpec.describe 'petit_poucet/breadcrumbs partial' do
  let(:view_paths) { [File.expand_path('../../lib/petit_poucet/views', __dir__)] }

  let(:view) do
    lookup_context = ActionView::LookupContext.new(view_paths)
    controller = ActionController::Base.new
    ActionView::Base
      .with_empty_template_cache
      .new(lookup_context, {}, controller)
      .tap { |v| v.singleton_class.include(PetitPoucet::ViewHelpers) }
  end

  def render_partial(crumbs)
    view.instance_variable_set(:@_breadcrumbs, crumbs)
    view.singleton_class.define_method(:breadcrumbs) { @_breadcrumbs }
    view.render(partial: 'petit_poucet/breadcrumbs')
  end

  let(:crumbs) { PetitPoucet::Breadcrumbs.new }

  it 'renders the nav landmark with ARIA label' do
    crumbs.add('Home', '/')
    html = render_partial(crumbs)

    expect(html).to include('<nav aria-label="Breadcrumb"')
  end

  it 'uses I18n key petit_poucet.aria_label for the nav label when set' do
    I18n.backend.store_translations(:en, petit_poucet: { aria_label: "Fil d'Ariane" })
    crumbs.add('Home', '/')

    html = render_partial(crumbs)

    expect(html).to include(%(<nav aria-label="Fil d&#39;Ariane"))
  ensure
    I18n.reload!
  end

  it 'renders a link for non-current crumbs' do
    crumbs.add('Home', '/').add('Articles', '/articles').add('My Post')
    html = render_partial(crumbs)

    expect(html).to include('<a href="/">Home</a>')
    expect(html).to include('<a href="/articles">Articles</a>')
  end

  it 'marks the current crumb with aria-current="page" on the <li>' do
    crumbs.add('Home', '/').add('Current')
    html = render_partial(crumbs)

    expect(html).to include('<li aria-current="page">Current</li>')
    expect(html).not_to include('<span aria-current')
  end

  it 'renders a non-current crumb with nil path as plain text without a link' do
    crumbs.add('Home', '/').add('Mid', nil).add('Last')
    html = render_partial(crumbs)

    expect(html).not_to include('<a href="">Mid</a>')
    expect(html).to include('Mid')
  end

  it 'renders nothing when the crumbs is empty' do
    html = render_partial(crumbs)

    expect(html.strip).to eq('')
  end
end
