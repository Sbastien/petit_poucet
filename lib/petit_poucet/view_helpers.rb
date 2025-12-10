# frozen_string_literal: true

module PetitPoucet
  module ViewHelpers
    # Iterate over breadcrumbs with full control over rendering
    #
    # @yield [crumb] Block called for each breadcrumb
    # @yieldparam crumb [CrumbPresenter] Presenter with name, path, current?
    # @return [Array<CrumbPresenter>] All breadcrumbs if no block given
    #
    # @example Without block
    #   breadcrumb_trail.each { |crumb| ... }
    #
    # @example With block
    #   breadcrumb_trail do |crumb|
    #     concat link_to(crumb.name, crumb.path) unless crumb.current?
    #   end
    #
    def breadcrumb_trail(&block)
      crumbs = breadcrumbs.each_with_index.map do |crumb, index|
        CrumbPresenter.new(
          name: crumb[:name],
          path: crumb[:path],
          current: index == breadcrumbs.size - 1
        )
      end

      return crumbs unless block_given?

      crumbs.each(&block)
    end

    # Simple default renderer for breadcrumbs
    #
    # @param options [Hash] Rendering options
    # @option options [String] :class CSS class for the container ('breadcrumb')
    # @option options [String] :separator Separator between crumbs (' / ')
    #
    # @return [ActiveSupport::SafeBuffer, nil] HTML or nil if no breadcrumbs
    #
    # @example Default rendering
    #   render_breadcrumbs
    #   # => <nav class="breadcrumb">Home / Articles / My Article</nav>
    #
    # @example Custom options
    #   render_breadcrumbs(class: 'custom-breadcrumb', separator: ' > ')
    #
    def render_breadcrumbs(options = {})
      return if breadcrumbs.empty?

      css_class = options[:class] || 'breadcrumb'
      separator = options[:separator] || ' / '

      items = breadcrumb_trail.map do |crumb|
        if crumb.path.present? && !crumb.current?
          link_to(crumb.name, crumb.path)
        else
          crumb.name
        end
      end

      content_tag(:nav, safe_join(items, separator.html_safe), class: css_class)
    end

    # Render breadcrumbs as JSON-LD structured data for SEO
    #
    # @return [ActiveSupport::SafeBuffer, nil] Script tag with JSON-LD or nil if no breadcrumbs
    #
    # @example In layout head
    #   <%= breadcrumb_json_ld %>
    #
    # @see https://schema.org/BreadcrumbList
    #
    def breadcrumb_json_ld
      return if breadcrumbs.empty?

      items = breadcrumb_trail.each_with_index.map { |crumb, index| json_ld_item(crumb, index) }
      json_ld = { '@context' => 'https://schema.org', '@type' => 'BreadcrumbList', 'itemListElement' => items }

      content_tag(:script, json_ld.to_json.html_safe, type: 'application/ld+json')
    end

    private

    def json_ld_item(crumb, index)
      item = { '@type' => 'ListItem', 'position' => index + 1, 'name' => crumb.name }
      item['item'] = url_for(crumb.path) if crumb.path.present? && !crumb.current?
      item
    end
  end
end
