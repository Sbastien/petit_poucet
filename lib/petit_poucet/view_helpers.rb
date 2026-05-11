# frozen_string_literal: true

module PetitPoucet
  module ViewHelpers
    # @yield [crumb] Block called for each breadcrumb
    # @yieldparam crumb [Presenter] Presenter with name, path, current?
    # @return [Array<Presenter>] All breadcrumbs if no block given
    def each_breadcrumb(&)
      ActiveSupport::Notifications.instrument('petit_poucet.render', size: breadcrumbs.size) do
        source = breadcrumbs
        crumbs = source.each_with_index.map do |crumb, index|
          Presenter.new(name: crumb.name, path: crumb.path, current: index == source.size - 1)
        end

        block_given? ? crumbs.each(&) : crumbs
      end
    end

    # @return [Array<String>]
    def breadcrumb_names = breadcrumbs.names

    # @return [Breadcrumb, nil] the last breadcrumb (the current page), or nil if empty
    def current_breadcrumb = breadcrumbs.last

    # @param separator [String] separator between crumbs
    # @param reverse [Boolean] reverse order, current page first
    # @return [String]
    def breadcrumb_title(separator: ' | ', reverse: false)
      names = breadcrumb_names
      names = names.reverse if reverse
      names.join(separator)
    end

    # @param base_url [String, nil] base URL for absolute paths
    # @return [ActiveSupport::SafeBuffer, nil] script tag or nil if empty
    def breadcrumb_json_ld(base_url: nil)
      crumbs = each_breadcrumb
      return if crumbs.empty?

      base_url ||= request&.base_url if respond_to?(:request)
      json_ld = build_json_ld(crumbs, base_url)
      content_tag(:script, ERB::Util.json_escape(json_ld.to_json).html_safe, type: 'application/ld+json')
    end

    private

    def build_json_ld(crumbs, base_url)
      {
        '@context' => 'https://schema.org',
        '@type' => 'BreadcrumbList',
        'itemListElement' => crumbs.each_with_index.map do |crumb, index|
          url = resolve_url(crumb.path, base_url)

          { '@type' => 'ListItem', 'position' => index + 1, 'name' => crumb.name }.tap do |item|
            item['item'] = url if url
          end
        end
      }
    end

    def resolve_url(path, base_url)
      return if path.nil?
      return path if path.start_with?('http://', 'https://')
      return "#{base_url}#{path}" if base_url && path.start_with?('/')

      path
    end
  end
end
