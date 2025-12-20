# frozen_string_literal: true

module PetitPoucet
  # View presenter for a breadcrumb with current state.
  #
  # @example
  #   crumb.name     # => "Home"
  #   crumb.path     # => "/"
  #   crumb.current? # => false
  #
  CrumbPresenter = Data.define(:name, :path, :current) do
    def initialize(name:, path:, current:) = super

    def current? = current
    def to_s = name
  end
end
