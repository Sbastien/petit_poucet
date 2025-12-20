# frozen_string_literal: true

require 'spec_helper'
require 'action_view'
require 'json'

RSpec.describe PetitPoucet::ViewHelpers do
  let(:view_class) do
    Class.new do
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::UrlHelper
      include ActionView::Context
      include PetitPoucet::ViewHelpers

      attr_accessor :output_buffer

      def initialize
        @_trail = PetitPoucet::Trail.new
      end

      def breadcrumbs
        @_trail
      end

      def request
        nil
      end
    end
  end

  let(:view) { view_class.new }

  def add_breadcrumb(name, path = nil)
    view.breadcrumbs.add(name, path)
  end

  describe '#breadcrumb_trail' do
    it 'returns empty array when no breadcrumbs' do
      expect(view.breadcrumb_trail).to eq([])
    end

    it 'returns CrumbPresenter objects with name and path' do
      add_breadcrumb('Home', '/')
      crumb = view.breadcrumb_trail.first

      expect(crumb).to be_a(PetitPoucet::CrumbPresenter)
      expect(crumb.name).to eq('Home')
      expect(crumb.path).to eq('/')
    end

    it 'marks only the last crumb as current' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')
      add_breadcrumb('Current')

      crumbs = view.breadcrumb_trail

      expect(crumbs.map(&:current?)).to eq([false, false, true])
    end

    it 'yields each crumb when block given' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Current')

      names = []
      view.breadcrumb_trail { |crumb| names << crumb.name }

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

  describe '#breadcrumb_json_ld' do
    it 'returns nil when no breadcrumbs' do
      expect(view.breadcrumb_json_ld).to be_nil
    end

    it 'generates valid JSON-LD structure' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')

      html = view.breadcrumb_json_ld
      expect(html).to include('type="application/ld+json"')

      json = JSON.parse(html.match(/>(.+)</m)[1])
      expect(json['@context']).to eq('https://schema.org')
      expect(json['@type']).to eq('BreadcrumbList')
      expect(json['itemListElement'].size).to eq(2)
    end

    it 'includes position for each item' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')

      html = view.breadcrumb_json_ld
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['position']).to eq(1)
      expect(json['itemListElement'][1]['position']).to eq(2)
    end

    it 'includes name for each item' do
      add_breadcrumb('Home', '/')
      add_breadcrumb('Articles', '/articles')

      html = view.breadcrumb_json_ld
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['name']).to eq('Home')
      expect(json['itemListElement'][1]['name']).to eq('Articles')
    end

    it 'includes item URL when path present' do
      add_breadcrumb('Home', '/')

      html = view.breadcrumb_json_ld
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['item']).to eq('/')
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

      view_with_request_class = Class.new do
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::UrlHelper
        include ActionView::Context
        include PetitPoucet::ViewHelpers

        attr_accessor :output_buffer, :request

        def initialize
          @_trail = PetitPoucet::Trail.new
        end

        def breadcrumbs
          @_trail
        end
      end

      view_with_request = view_with_request_class.new
      view_with_request.request = fake_request
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

    it 'works when respond_to?(:request) is false' do
      view_without_request_class = Class.new do
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::UrlHelper
        include ActionView::Context
        include PetitPoucet::ViewHelpers

        attr_accessor :output_buffer

        def initialize
          @_trail = PetitPoucet::Trail.new
        end

        def breadcrumbs
          @_trail
        end
      end

      view_without_request = view_without_request_class.new
      view_without_request.breadcrumbs.add('Home', '/')

      html = view_without_request.breadcrumb_json_ld
      json = JSON.parse(html.match(/>(.+)</m)[1])

      expect(json['itemListElement'][0]['item']).to eq('/')
    end
  end
end
