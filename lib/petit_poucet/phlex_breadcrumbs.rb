# frozen_string_literal: true

require 'phlex'

module PetitPoucet
  # Phlex component rendering the breadcrumbs with ARIA-compliant markup.
  #
  # @example In a Phlex view
  #   render(PetitPoucet::PhlexBreadcrumbs.new(crumbs: helpers.breadcrumbs))
  #
  class PhlexBreadcrumbs < Phlex::HTML
    def initialize(crumbs:)
      super()
      @crumbs = crumbs
    end

    def view_template
      return if @crumbs.empty?

      nav(aria_label: I18n.t('petit_poucet.aria_label', default: 'Breadcrumb'), class: 'petit-poucet-breadcrumbs') do
        ol do
          @crumbs.each_with_index do |crumb, index|
            current = index == @crumbs.size - 1
            if current
              li(aria_current: 'page') { plain crumb.name }
            else
              li { render_crumb(crumb) }
            end
          end
        end
      end
    end

    private

    def render_crumb(crumb)
      if crumb.path.nil?
        plain crumb.name
      else
        a(href: crumb.path) { plain crumb.name }
      end
    end
  end
end
