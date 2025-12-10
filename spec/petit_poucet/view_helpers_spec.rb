# frozen_string_literal: true

require 'spec_helper'
require 'action_view'

RSpec.describe PetitPoucet::ViewHelpers do
  let(:view_class) do
    Class.new do
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::UrlHelper
      include ActionView::Context
      include PetitPoucet::ViewHelpers

      attr_accessor :breadcrumbs, :output_buffer
    end
  end

  let(:view) { view_class.new }

  describe '#breadcrumb_trail' do
    it 'returns empty array when no breadcrumbs' do
      view.breadcrumbs = []
      expect(view.breadcrumb_trail).to eq([])
    end

    it 'returns CrumbPresenter objects with name and path' do
      view.breadcrumbs = [{ name: 'Home', path: '/' }]
      crumb = view.breadcrumb_trail.first

      expect(crumb).to be_a(PetitPoucet::CrumbPresenter)
      expect(crumb.name).to eq('Home')
      expect(crumb.path).to eq('/')
    end

    it 'marks only the last crumb as current' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'Articles', path: '/articles' },
        { name: 'Current', path: nil }
      ]
      crumbs = view.breadcrumb_trail

      expect(crumbs.map(&:current?)).to eq([false, false, true])
    end

    it 'yields each crumb when block given' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'Current', path: nil }
      ]

      names = []
      view.breadcrumb_trail { |crumb| names << crumb.name }

      expect(names).to eq(%w[Home Current])
    end
  end

  describe '#render_breadcrumbs' do
    it 'returns nil when no breadcrumbs' do
      view.breadcrumbs = []
      expect(view.render_breadcrumbs).to be_nil
    end

    it 'renders breadcrumbs with default options' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'Articles', path: '/articles' },
        { name: 'Current', path: nil }
      ]

      html = view.render_breadcrumbs
      expect(html).to include('<nav class="breadcrumb">')
      expect(html).to include('<a href="/">Home</a>')
      expect(html).to include('<a href="/articles">Articles</a>')
      expect(html).to include('Current')
      expect(html).to include(' / ')
    end

    it 'renders with custom class' do
      view.breadcrumbs = [{ name: 'Home', path: '/' }]

      html = view.render_breadcrumbs(class: 'my-breadcrumb')
      expect(html).to include('<nav class="my-breadcrumb">')
    end

    it 'renders with custom separator' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'Current', path: nil }
      ]

      html = view.render_breadcrumbs(separator: ' > ')
      expect(html).to include(' > ')
      expect(html).not_to include(' / ')
    end

    it 'does not link the current breadcrumb' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'Current', path: '/current' }
      ]

      html = view.render_breadcrumbs
      expect(html).to include('<a href="/">Home</a>')
      expect(html).not_to include('<a href="/current">')
      expect(html).to include('Current')
    end

    it 'does not link breadcrumbs without path' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'No Link', path: nil },
        { name: 'Current', path: nil }
      ]

      html = view.render_breadcrumbs
      expect(html).to include('<a href="/">Home</a>')
      expect(html).to include('No Link')
      expect(html).not_to include('<a href="">No Link</a>')
    end
  end

  describe '#breadcrumb_json_ld' do
    before do
      allow(view).to receive(:url_for) { |path| "https://example.com#{path}" }
    end

    it 'returns nil when no breadcrumbs' do
      view.breadcrumbs = []
      expect(view.breadcrumb_json_ld).to be_nil
    end

    it 'renders JSON-LD script tag' do
      view.breadcrumbs = [{ name: 'Home', path: '/' }]

      html = view.breadcrumb_json_ld
      expect(html).to include('<script type="application/ld+json">')
      expect(html).to include('</script>')
    end

    it 'includes schema.org context and type' do
      view.breadcrumbs = [{ name: 'Home', path: '/' }]

      html = view.breadcrumb_json_ld
      expect(html).to include('"@context":"https://schema.org"')
      expect(html).to include('"@type":"BreadcrumbList"')
    end

    it 'renders breadcrumbs as ListItem elements' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'Articles', path: '/articles' }
      ]

      html = view.breadcrumb_json_ld
      json = JSON.parse(html.match(%r{<script[^>]*>(.+)</script>})[1])

      expect(json['itemListElement'].size).to eq(2)
      expect(json['itemListElement'][0]).to include(
        '@type' => 'ListItem',
        'position' => 1,
        'name' => 'Home',
        'item' => 'https://example.com/'
      )
      expect(json['itemListElement'][1]).to include(
        '@type' => 'ListItem',
        'position' => 2,
        'name' => 'Articles'
      )
    end

    it 'does not include item URL for current breadcrumb' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'Current', path: '/current' }
      ]

      html = view.breadcrumb_json_ld
      json = JSON.parse(html.match(%r{<script[^>]*>(.+)</script>})[1])

      expect(json['itemListElement'][0]).to have_key('item')
      expect(json['itemListElement'][1]).not_to have_key('item')
    end

    it 'does not include item URL for breadcrumbs without path' do
      view.breadcrumbs = [
        { name: 'Home', path: '/' },
        { name: 'No Link', path: nil },
        { name: 'Current', path: nil }
      ]

      html = view.breadcrumb_json_ld
      json = JSON.parse(html.match(%r{<script[^>]*>(.+)</script>})[1])

      expect(json['itemListElement'][0]).to have_key('item')
      expect(json['itemListElement'][1]).not_to have_key('item')
      expect(json['itemListElement'][2]).not_to have_key('item')
    end
  end
end
