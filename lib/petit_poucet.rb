# frozen_string_literal: true

require_relative 'petit_poucet/version'
require_relative 'petit_poucet/crumb'
require_relative 'petit_poucet/trail'
require_relative 'petit_poucet/crumb_presenter'
require_relative 'petit_poucet/controller'
require_relative 'petit_poucet/view_helpers'
# :nocov:
require_relative 'petit_poucet/railtie' if defined?(Rails::Railtie)
# :nocov:

module PetitPoucet
end
