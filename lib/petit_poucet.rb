# frozen_string_literal: true

require_relative 'petit_poucet/version'
require_relative 'petit_poucet/crumb'
require_relative 'petit_poucet/crumb_presenter'
require_relative 'petit_poucet/controller_methods'
require_relative 'petit_poucet/view_helpers'
require_relative 'petit_poucet/railtie' if defined?(Rails::Railtie)

module PetitPoucet
end
