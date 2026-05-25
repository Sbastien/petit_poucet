# frozen_string_literal: true

require 'spec_helper'
require 'rails'
require 'rails/all'
require 'view_component'
require 'view_component/test_helpers'
require 'petit_poucet/breadcrumbs_component'

# Minimal Rails app required by ViewComponent::TestHelpers#render_inline.
unless defined?(BreadcrumbsComponentSpecApp)
  class BreadcrumbsComponentSpecApp < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = 'test_secret_for_petit_poucet_component_spec'
  end
  BreadcrumbsComponentSpecApp.initialize!

  class ApplicationController < ActionController::Base
    include PetitPoucet::Controller
  end
end

RSpec.describe PetitPoucet::BreadcrumbsComponent, type: :component do
  include ViewComponent::TestHelpers

  def b(name, path = nil) = PetitPoucet::Breadcrumb.new(name, path)

  def crumbs_with(*pebbles)
    PetitPoucet::Breadcrumbs.new.tap do |t|
      pebbles.each { |p| t.add(p.name, p.path) }
    end
  end

  # Render inline and return the Nokogiri document fragment.
  def render_component(crumbs: nil)
    if crumbs
      render_inline(described_class.new(crumbs: crumbs))
    else
      render_inline(described_class.new)
    end
  end

  describe '#render?' do
    it 'renders nothing when collection is empty' do
      render_component(crumbs: crumbs_with)

      expect(rendered_content).to be_blank
    end

    it 'renders output when collection has any pebbles' do
      render_component(crumbs: crumbs_with(b('Home', '/')))

      expect(rendered_content).not_to be_blank
    end
  end

  describe 'rendered markup' do
    it 'renders an ARIA-compliant <nav> with aria-label="Breadcrumb"' do
      doc = render_component(crumbs: crumbs_with(b('Home', '/')))

      expect(doc.css('nav[aria-label="Breadcrumb"]')).not_to be_empty
    end

    it 'renders links for non-current crumbs that have paths' do
      doc = render_component(crumbs: crumbs_with(b('Home', '/'), b('Articles', '/articles'), b('My Article')))

      expect(doc.at_css('a[href="/"]').text).to eq('Home')
      expect(doc.at_css('a[href="/articles"]').text).to eq('Articles')
    end

    it 'marks the current (last) crumb with aria-current="page" on the <li>' do
      doc = render_component(crumbs: crumbs_with(b('Home', '/'), b('Current')))

      expect(doc.at_css('li[aria-current="page"]').text.strip).to eq('Current')
      expect(doc.at_css('span[aria-current="page"]')).to be_nil
    end

    it 'renders a non-current crumb with nil path as plain text (no link)' do
      doc = render_component(crumbs: crumbs_with(b('Home', '/'), b('Mid', nil), b('Last')))

      expect(rendered_content).to include('Mid')
      expect(doc.css('a').map(&:text)).not_to include('Mid')
    end
  end

  describe 'fallback to helpers.breadcrumbs when no explicit collection given' do
    it 'uses helpers.breadcrumbs from the controller' do
      with_controller_class(ApplicationController) do
        vc_test_controller.instance_variable_set(
          :@_breadcrumbs,
          PetitPoucet::Breadcrumbs.new.tap do |t|
            t.add('Home', '/')
            t.add('Implicit', '/implicit')
          end
        )

        doc = render_component

        expect(doc.at_css('a[href="/"]').text).to eq('Home')
        expect(doc.at_css('li[aria-current="page"]').text.strip).to eq('Implicit')
      end
    end
  end
end
