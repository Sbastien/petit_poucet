# frozen_string_literal: true

require 'spec_helper'
require 'phlex'
require 'petit_poucet/phlex_breadcrumbs'

RSpec.describe PetitPoucet::PhlexBreadcrumbs do
  def b(name, path = nil) = PetitPoucet::Breadcrumb.new(name, path)

  def crumbs_with(*pebbles)
    PetitPoucet::Breadcrumbs.new.tap do |t|
      pebbles.each { |p| t.add(p.name, p.path) }
    end
  end

  def render(component)
    component.call
  end

  describe 'empty collection' do
    it 'renders nothing' do
      output = render(described_class.new(crumbs: crumbs_with))

      expect(output).to be_empty
    end
  end

  describe 'rendered markup' do
    it 'renders an ARIA-compliant nav with aria-label' do
      output = render(described_class.new(crumbs: crumbs_with(b('Home', '/'))))

      expect(output).to include('<nav aria-label="Breadcrumb"')
      expect(output).to include('class="petit-poucet-breadcrumbs"')
    end

    it 'renders an <a> for non-current crumbs with paths' do
      collection = crumbs_with(b('Home', '/'), b('Articles', '/articles'), b('Current'))
      output = render(described_class.new(crumbs: collection))

      expect(output).to include('<a href="/">Home</a>')
      expect(output).to include('<a href="/articles">Articles</a>')
    end

    it 'marks the current (last) crumb with aria-current="page" on the <li>' do
      output = render(described_class.new(crumbs: crumbs_with(b('Home', '/'), b('Current'))))

      expect(output).to include('<li aria-current="page">Current</li>')
      expect(output).not_to include('<span aria-current')
    end

    it 'renders a non-current crumb with nil path as plain text inside <li>' do
      output = render(described_class.new(crumbs: crumbs_with(b('Home', '/'), b('Mid'), b('Last'))))

      expect(output).to include('<li>Mid</li>')
      expect(output).not_to include('<a href="">Mid</a>')
    end

    it 'wraps the list in <ol>' do
      output = render(described_class.new(crumbs: crumbs_with(b('Home', '/'), b('Last'))))

      expect(output).to include('<ol>')
      expect(output).to include('</ol>')
    end
  end
end
