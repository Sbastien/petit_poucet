# frozen_string_literal: true

require 'view_component'

module PetitPoucet
  # ViewComponent rendering the breadcrumbs with ARIA-compliant markup.
  #
  # @example In an ERB template
  #   <%= render(PetitPoucet::BreadcrumbsComponent.new) %>
  #
  # @example With an explicit collection
  #   <%= render(PetitPoucet::BreadcrumbsComponent.new(crumbs: my_breadcrumbs)) %>
  class BreadcrumbsComponent < ViewComponent::Base
    def initialize(crumbs: nil)
      super()
      @crumbs = crumbs
    end

    def render?
      presented_crumbs.any?
    end

    private

    def presented_crumbs
      @presented_crumbs ||= source.each_with_index.map do |crumb, index|
        Presenter.new(name: crumb.name, path: crumb.path, current: index == source.size - 1)
      end
    end

    def source
      @crumbs || helpers.breadcrumbs
    end
  end
end
