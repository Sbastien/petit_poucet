# frozen_string_literal: true

require 'spec_helper'
require 'action_view'
require 'json'

RSpec.describe PetitPoucet::ViewHelpers do
  def build_view(**options)
    klass = Class.new do
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::UrlHelper
      include ActionView::Context
      include PetitPoucet::ViewHelpers

      attr_accessor :output_buffer, :request

      def initialize(request = nil)
        @_breadcrumbs = PetitPoucet::Breadcrumbs.new
        @request = request
      end

      def breadcrumbs = @_breadcrumbs
    end

    klass.new(options[:request])
  end

  let(:view) { build_view }

  def add_breadcrumb(name, path = nil)
    view.breadcrumbs.add(name, path)
  end

  describe '#each_breadcrumb' do
    it 'returns empty array when no breadcrumbs' do
      expect(view.each_breadcrumb).to eq([])
    end

    it 'returns Presenter objects with name and path' do
      add_breadcrumb('Home', '/')
      crumb = view.each_breadcrumb.first

      expect(crumb).to be_a(PetitPoucet::Presenter)
      expect(crumb.name).to eq('Home')
      expect(crumb.path).to eq('/')
    end

    it 'marks only the last crumb as current' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')
      add_breadcrumb('Current')

      crumbs = view.each_breadcrumb

      expect(crumbs.map(&:current?)).to eq([false, false, true])
    end

    it 'yields each crumb when block given' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Current')

      names = []
      view.each_breadcrumb { |crumb| names << crumb.name }

      expect(names).to eq(%w[Home Current])
    end
  end

  describe '#breadcrumb_names' do
    it 'returns empty array when no breadcrumbs' do
      expect(view.breadcrumb_names).to eq([])
    end

    it 'returns array of names' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')
      add_breadcrumb('My Article')

      expect(view.breadcrumb_names).to eq(['Home', 'Articles', 'My Article'])
    end
  end

  describe '#current_breadcrumb' do
    it 'returns nil when there are no breadcrumbs' do
      expect(view.current_breadcrumb).to be_nil
    end

    it 'returns the last breadcrumb' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')
      add_breadcrumb('My Article')

      expect(view.current_breadcrumb).to eq(PetitPoucet::Breadcrumb.new('My Article'))
    end
  end

  describe '#breadcrumb_title' do
    before do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')
      add_breadcrumb('My Article')
    end

    it 'joins names with default separator' do
      expect(view.breadcrumb_title).to eq('Home | Articles | My Article')
    end

    it 'uses custom separator' do
      expect(view.breadcrumb_title(separator: ' > ')).to eq('Home > Articles > My Article')
    end

    it 'reverses order when requested' do
      expect(view.breadcrumb_title(reverse: true)).to eq('My Article | Articles | Home')
    end

    it 'combines custom separator and reverse' do
      expect(view.breadcrumb_title(separator: ' - ', reverse: true)).to eq('My Article - Articles - Home')
    end

    it 'returns empty string when no breadcrumbs' do
      view.breadcrumbs.clear
      expect(view.breadcrumb_title).to eq('')
    end
  end

  describe 'instrumentation' do
    it 'emits a petit_poucet.render notification with size payload' do
      view = build_view
      view.breadcrumbs.add('Home', '/')
      view.breadcrumbs.add('Articles', '/articles')

      events = []
      subscriber = ActiveSupport::Notifications.subscribe('petit_poucet.render') do |*, payload|
        events << payload
      end

      view.each_breadcrumb

      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(events).to contain_exactly(hash_including(size: 2))
    end
  end

  describe '#breadcrumb_json_ld' do
    it 'returns nil when no breadcrumbs' do
      expect(view.breadcrumb_json_ld).to be_nil
    end

    it 'generates a script tag with schema.org BreadcrumbList payload' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')

      html = view.breadcrumb_json_ld
      expect(html).to include('type="application/ld+json"')

      json = JSON.parse(html.match(/>(.+)</m)[1])
      expect(json).to include('@context' => 'https://schema.org', '@type' => 'BreadcrumbList')
      expect(json['itemListElement']).to eq(
        [
          { '@type' => 'ListItem', 'position' => 1, 'name' => 'Home', 'item' => '/' },
          { '@type' => 'ListItem', 'position' => 2, 'name' => 'Articles', 'item' => '/articles' }
        ]
      )
    end

    it 'omits item when path nil' do
      add_breadcrumb('Current')

      html = view.breadcrumb_json_ld
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]).not_to have_key('item')
    end

    it 'prepends base_url to relative paths' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')

      html = view.breadcrumb_json_ld(base_url: 'https://example.com')
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['item']).to eq('https://example.com/')
      expect(json['itemListElement'][1]['item']).to eq('https://example.com/articles')
    end

    it 'preserves absolute URLs' do
      add_breadcrumb('External', 'https://other.com/page')

      html = view.breadcrumb_json_ld(base_url: 'https://example.com')
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['item']).to eq('https://other.com/page')
    end

    it 'uses request.base_url when no explicit base_url given' do
      fake_request = Struct.new(:base_url).new('https://myapp.com')
      view_with_request = build_view(request: fake_request)
      view_with_request.breadcrumbs.add('Home', '/')

      html = view_with_request.breadcrumb_json_ld
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['item']).to eq('https://myapp.com/')
    end

    it 'returns relative path as-is when no base_url and path does not start with /' do
      add_breadcrumb('Page', 'some/relative/path')

      html = view.breadcrumb_json_ld
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['item']).to eq('some/relative/path')
    end

    it 'escapes script-closing tags to prevent XSS' do
      add_breadcrumb('</script><script>alert(1)</script>', '/')

      html = view.breadcrumb_json_ld
      expect(html).not_to include('</script><script>')

      json = JSON.parse(html.match(%r{>(.+)</script>}m)[1])
      expect(json['itemListElement'][0]['name']).to eq('</script><script>alert(1)</script>')
    end

    it 'works when respond_to?(:request) is false' do
      klass = Class.new do
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::UrlHelper
        include ActionView::Context
        include PetitPoucet::ViewHelpers

        attr_accessor :output_buffer

        def initialize = @_breadcrumbs = PetitPoucet::Breadcrumbs.new
        def breadcrumbs = @_breadcrumbs
      end

      view_without_request = klass.new
      view_without_request.breadcrumbs.add('Home', '/')

      html = view_without_request.breadcrumb_json_ld
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['item']).to eq('/')
    end
  end
end
