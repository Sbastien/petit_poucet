# frozen_string_literal: true

module PetitPoucet
  # Controller concern providing breadcrumb functionality.
  module Controller
    extend ActiveSupport::Concern

    included do
      helper_method(:breadcrumbs) if respond_to?(:helper_method)
      before_action(:_reset_breadcrumbs, prepend: true) if respond_to?(:before_action)
    end

    class_methods do
      # Registers a static breadcrumb declaration.
      #
      # Path may be a String (used verbatim), a Symbol (sent to the controller),
      # or a Proc (instance_exec'd in the controller). Filter options pass
      # through to `before_action` (only:, except:, if:, unless:, ...).
      #
      # For dynamic logic, mutate `breadcrumbs` from inside an action.
      def breadcrumbs(name, path = nil, **opts)
        before_action(**opts) { breadcrumbs.add(name, _resolve_breadcrumb_path(path)) }
      end
    end

    # @yield [breadcrumbs] Optional block that receives the Breadcrumbs collection
    # @return [Breadcrumbs] the breadcrumbs collection
    def breadcrumbs
      @_breadcrumbs ||= Breadcrumbs.new
      yield @_breadcrumbs if block_given?
      @_breadcrumbs
    end

    private

    def _reset_breadcrumbs
      @_breadcrumbs = Breadcrumbs.new
    end

    def _resolve_breadcrumb_path(path)
      case path
      when Symbol then send(path)
      when Proc   then instance_exec(&path)
      else path
      end
    end
  end
end
