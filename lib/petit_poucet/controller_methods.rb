# frozen_string_literal: true

module PetitPoucet
  module ControllerMethods
    extend ActiveSupport::Concern

    included do
      class_attribute :_breadcrumb_definitions, default: []
      helper_method :breadcrumbs if respond_to?(:helper_method)
    end

    class_methods do
      # Declare a breadcrumb at the class level
      #
      # @param name [String, Symbol, Proc] The breadcrumb label
      # @param path [String, Symbol, Proc, nil] The breadcrumb URL
      # @param options [Hash] Options including :only and :except
      #
      def breadcrumb(name, path = nil, **options)
        _add_breadcrumb_definition(Crumb.new(name, path, **options))
      end

      # Clear all inherited breadcrumbs
      #
      # @param options [Hash] Options including :only and :except to conditionally clear
      #
      def clear_breadcrumbs(**options)
        if options.empty?
          self._breadcrumb_definitions = []
        else
          _add_breadcrumb_definition(Crumb.new(clear: true, **options))
        end
      end

      # Group multiple breadcrumbs with shared options
      #
      # @param options [Hash] Options including :only and :except applied to all breadcrumbs in block
      # @yield Block containing breadcrumb declarations
      #
      # @example
      #   breadcrumb_group only: %i[index show edit] do
      #     breadcrumb 'Home', '/'
      #     breadcrumb 'Section', '/section'
      #   end
      #
      def breadcrumb_group(**options, &block)
        BreadcrumbGroupBuilder.new(self, options).instance_eval(&block)
      end

      private

      def _add_breadcrumb_definition(crumb)
        self._breadcrumb_definitions = _breadcrumb_definitions + [crumb]
      end
    end

    # Add a breadcrumb dynamically within an action
    #
    # @param name [String, Proc] The breadcrumb label
    # @param path [String, nil] The breadcrumb URL
    #
    def breadcrumb(name, path = nil)
      @runtime_breadcrumbs ||= []
      @runtime_breadcrumbs << Crumb.new(name, path)
    end

    # Clear runtime breadcrumbs
    def clear_breadcrumbs
      @runtime_breadcrumbs = []
    end

    # Get all resolved breadcrumbs for the current action
    #
    # @return [Array<Hash>] Array of { name:, path: } hashes
    #
    def breadcrumbs
      @breadcrumbs ||= resolve_breadcrumbs
    end

    def resolve_breadcrumbs
      crumbs = []
      _breadcrumb_definitions.each do |crumb|
        next unless crumb.applies_to_action?(action_name)

        crumb.clear? ? crumbs.clear : crumbs << crumb
      end
      crumbs += @runtime_breadcrumbs || []
      crumbs.map { |crumb| { name: crumb.resolve_name(self), path: crumb.resolve_path(self) } }
    end
  end
end
