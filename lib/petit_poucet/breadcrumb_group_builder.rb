# frozen_string_literal: true

module PetitPoucet
  class BreadcrumbGroupBuilder
    def initialize(controller_class, options, parent_options = nil)
      @controller_class = controller_class
      @options = merge_action_options(parent_options, options)
    end

    def breadcrumb(name, path = nil, **options)
      merged_options = merge_action_options(@options, options)
      add_definition(Crumb.new(name, path, **merged_options))
    end

    def breadcrumb_group(**options, &block)
      BreadcrumbGroupBuilder.new(@controller_class, options, @options).instance_eval(&block)
    end

    def clear_breadcrumbs(**options)
      merged_options = options.empty? ? @options : merge_action_options(@options, options)
      add_definition(Crumb.new(clear: true, **merged_options))
    end

    private

    def add_definition(crumb)
      @controller_class._breadcrumb_definitions = @controller_class._breadcrumb_definitions + [crumb]
    end

    def merge_action_options(base, override)
      return override if base.nil? || base.empty?
      return base if override.nil? || override.empty?

      {}.tap do |result|
        result[:only] = merge_only(base[:only], override[:only])
        result[:except] = merge_except(base[:except], override[:except])
        result.compact!
      end
    end

    def merge_only(base_only, override_only)
      return base_only unless override_only
      return override_only unless base_only

      # Intersection: more restrictive
      base_arr = Array(base_only).map(&:to_s)
      override_arr = Array(override_only).map(&:to_s)
      (base_arr & override_arr).map(&:to_sym)
    end

    def merge_except(base_except, override_except)
      return nil if base_except.nil? && override_except.nil?

      # Union: cumulative exclusions
      base_arr = Array(base_except).map(&:to_s)
      override_arr = Array(override_except).map(&:to_s)
      (base_arr | override_arr).map(&:to_sym)
    end
  end
end
