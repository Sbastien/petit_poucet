# frozen_string_literal: true

require_relative 'petit_poucet/version'
require_relative 'petit_poucet/breadcrumb'
require_relative 'petit_poucet/breadcrumbs'
require_relative 'petit_poucet/presenter'

# :nocov:
require_relative 'petit_poucet/controller' if defined?(ActiveSupport::Concern)
require_relative 'petit_poucet/view_helpers' if defined?(ActionView)
require_relative 'petit_poucet/breadcrumbs_component' if defined?(ViewComponent::Base)
require_relative 'petit_poucet/phlex_breadcrumbs' if defined?(Phlex::HTML)
require_relative 'petit_poucet/railtie' if defined?(Rails::Railtie)
# :nocov:

module PetitPoucet
end
