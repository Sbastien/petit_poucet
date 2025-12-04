# frozen_string_literal: true

module PetitPoucet
  # Presenter for a single breadcrumb in views
  #
  # @example
  #   crumb.name      # => "Home"
  #   crumb.path      # => "/"
  #   crumb.current?  # => false
  #
  class CrumbPresenter
    attr_reader :name, :path

    def initialize(name:, path:, current:)
      @name = name
      @path = path
      @current = current
    end

    def current?
      @current
    end

    def to_s
      name
    end
  end
end
