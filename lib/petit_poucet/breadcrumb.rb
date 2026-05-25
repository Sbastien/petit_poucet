# frozen_string_literal: true

module PetitPoucet
  # Immutable value object representing a single breadcrumb.
  #
  # @example
  #   crumb = Breadcrumb.new("Home", "/")
  #   crumb.name # => "Home"
  #   crumb.path # => "/"
  #
  # @raise [ArgumentError] if name is nil or empty
  #
  Breadcrumb = Data.define(:name, :path) do
    def initialize(name:, path: nil)
      raise ArgumentError, 'name cannot be nil or empty' if name.nil? || name.to_s.strip.empty?

      super(name: -name.to_s, path: path&.then { -_1.to_s })
    end
  end
end
