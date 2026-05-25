# frozen_string_literal: true

require_relative 'breadcrumb'

module PetitPoucet
  # Breadcrumbs represents an ordered collection of breadcrumbs.
  #
  # A pure Ruby class with no Rails dependencies, making it
  # easy to test in isolation and use outside of Rails if needed.
  #
  # @example Building a breadcrumbs collection
  #   crumbs = Breadcrumbs.new
  #   crumbs.add("Home", "/")
  #   crumbs.add("Articles", "/articles")
  #   crumbs.add("Ruby Guide")
  #
  # @example Manipulating breadcrumbs
  #   crumbs.prepend("Admin", "/admin")
  #   crumbs.insert_after("Home", "Dashboard", "/dashboard")
  #   crumbs.remove("Articles")
  #
  class Breadcrumbs
    include Enumerable

    def initialize = @crumbs = []

    # Adds a breadcrumb at the end of the breadcrumbs collection.
    #
    # @param name [String] the breadcrumb label
    # @param path [String, nil] the breadcrumb URL
    # @return [Breadcrumbs] self for chaining
    def add(name, path = nil)
      @crumbs << Breadcrumb.new(name, path)
      self
    end

    # Adds a breadcrumb at the beginning of the breadcrumbs collection.
    #
    # @param name [String] the breadcrumb label
    # @param path [String, nil] the breadcrumb URL
    # @return [Breadcrumbs] self for chaining
    def prepend(name, path = nil)
      @crumbs.unshift(Breadcrumb.new(name, path))
      self
    end

    # Inserts a breadcrumb after an existing one.
    #
    # @param target_name [String] the name of the breadcrumb to insert after
    # @param name [String] the breadcrumb label
    # @param path [String, nil] the breadcrumb URL
    # @return [Breadcrumbs] self for chaining (no-op if target not found)
    def insert_after(target_name, name, path = nil)
      index = find_index_by_name(target_name)
      @crumbs.insert(index + 1, Breadcrumb.new(name, path)) if index
      self
    end

    # Inserts a breadcrumb before an existing one.
    #
    # @param target_name [String] the name of the breadcrumb to insert before
    # @param name [String] the breadcrumb label
    # @param path [String, nil] the breadcrumb URL
    # @return [Breadcrumbs] self for chaining (no-op if target not found)
    def insert_before(target_name, name, path = nil)
      index = find_index_by_name(target_name)
      @crumbs.insert(index, Breadcrumb.new(name, path)) if index
      self
    end

    # Removes a breadcrumb by name.
    #
    # @param name [String] the name of the breadcrumb to remove
    # @return [Breadcrumbs] self for chaining
    def remove(name)
      @crumbs.reject! { _1.name == name }
      self
    end

    # Replaces a breadcrumb by name.
    #
    # @param target_name [String] the name of the breadcrumb to replace
    # @param name [String] the new breadcrumb label
    # @param path [String, nil] the new breadcrumb URL
    # @return [Breadcrumbs] self for chaining (no-op if target not found)
    def replace(target_name, name, path = nil)
      index = find_index_by_name(target_name)
      @crumbs[index] = Breadcrumb.new(name, path) if index
      self
    end

    # Checks if a breadcrumb with the given name exists.
    #
    # @param name [String] the name to search for
    # @return [Boolean]
    def exists?(name) = @crumbs.any? { _1.name == name }

    # Finds a breadcrumb by name.
    #
    # @param name [String] the name to search for
    # @return [Breadcrumb, nil] the breadcrumb or nil if not found
    def find_by_name(name) = @crumbs.find { _1.name == name }

    # Removes all breadcrumbs from the collection.
    #
    # @return [Breadcrumbs] self for chaining
    def clear
      @crumbs.clear
      self
    end

    # Iterates over each breadcrumb.
    #
    # @yield [Breadcrumb] each breadcrumb
    # @return [Enumerator] if no block given
    def each(&block)
      return enum_for(:each) { size } unless block

      @crumbs.each(&block)
    end

    # @return [Integer] number of breadcrumbs
    def size = @crumbs.size
    alias length size

    # @return [Boolean] true if there are no breadcrumbs
    def empty? = @crumbs.empty?

    # @param count [Integer, nil] return the last `count` crumbs (as Array) when given
    # @return [Breadcrumb, Array<Breadcrumb>, nil] the last crumb, last `count`, or nil if empty
    def last(...) = @crumbs.last(...)

    # Access a breadcrumb by index.
    #
    # @param index [Integer] the index
    # @return [Breadcrumb, nil] the breadcrumb at that index
    def [](index) = @crumbs[index]

    # @return [Array<String>] array of breadcrumb names
    def names = @crumbs.map(&:name)

    # @return [Array<Breadcrumb>] a copy of the internal crumbs array
    def to_a = @crumbs.dup

    # @param other [Breadcrumbs] the object to compare
    # @return [Boolean]
    def ==(other) = other.is_a?(Breadcrumbs) && @crumbs == other.to_a

    # Returns a developer-friendly string representation.
    #
    # @return [String] inspection string
    # @example
    #   crumbs.inspect
    #   #=> '#<PetitPoucet::Breadcrumbs ["Home"=>"/", "Articles"=>"/articles", "Ruby Guide"=>nil]>'
    def inspect
      crumb_list = @crumbs.map { |c| "#{c.name.inspect}=>#{c.path.inspect}" }.join(', ')
      "#<PetitPoucet::Breadcrumbs [#{crumb_list}]>"
    end

    private

    def find_index_by_name(name) = @crumbs.index { _1.name == name }
  end
end
