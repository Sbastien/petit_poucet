# frozen_string_literal: true

module PetitPoucet
  # Controller concern providing breadcrumb functionality.
  module Controller
    extend ActiveSupport::Concern

    included do
      class_attribute :_breadcrumb_blocks, default: []
      # :nocov:
      helper_method :breadcrumbs if respond_to?(:helper_method)
      # :nocov:
    end

    class_methods do
      # @param only [Array<Symbol>, Symbol] Only run block for these actions
      # @param except [Array<Symbol>, Symbol] Don't run block for these actions
      # @yield [trail] Block that receives the Trail object
      def breadcrumbs(only: nil, except: nil, &block)
        return unless block_given?

        self._breadcrumb_blocks = _breadcrumb_blocks + [wrap_block(block, only, except)]
      end

      def clear_breadcrumbs = self._breadcrumb_blocks = []

      private

      def wrap_block(block, only, except)
        return block unless only || except

        actions = Array(only || except).map(&:to_s)
        should_include = only.present?

        proc do |trail|
          run = should_include == actions.include?(action_name)
          instance_exec(trail, &block) if run
        end
      end
    end

    # @yield [trail] Optional block that receives the Trail object
    # @return [Trail] the breadcrumb trail
    def breadcrumbs
      @_trail ||= build_trail
      yield @_trail if block_given?
      @_trail
    end

    private

    def build_trail
      trail = Trail.new
      _breadcrumb_blocks.each { instance_exec(trail, &_1) }
      trail
    end
  end
end
