# frozen_string_literal: true

module PetitPoucet
  # Trail represents an ordered collection of breadcrumbs.
  #
  # A pure Ruby class with no Rails dependencies, making it
  # easy to test in isolation and use outside of Rails if needed.
  #
  # @example Building a trail
  #   trail = Trail.new
  #   trail.add("Home", "/")
  #   trail.add("Articles", "/articles")
  #   trail.add("Ruby Guide")
  #
  # @example Manipulating the trail
  #   trail.prepend("Admin", "/admin")
  #   trail.insert_after("Home", "Dashboard", "/dashboard")
  #   trail.remove("Articles")
  #
  class Trail
    include Enumerable

    def initialize = @crumbs = []

    # Adds a breadcrumb at the end of the trail.
    #
    # @param name [String] the breadcrumb label
    # @param path [String, nil] the breadcrumb URL
    # @return [Trail] self for chaining
    def add(name, path = nil)
      @crumbs << Crumb.new(name, path)
      self
    end

    # Adds a breadcrumb at the beginning of the trail.
    #
    # @param name [String] the breadcrumb label
    # @param path [String, nil] the breadcrumb URL
    # @return [Trail] self for chaining
    def prepend(name, path = nil)
      @crumbs.unshift(Crumb.new(name, path))
      self
    end

    # Inserts a breadcrumb after an existing one.
    #
    # @param target_name [String] the name of the crumb to insert after
    # @param name [String] the breadcrumb label
    # @param path [String, nil] the breadcrumb URL
    # @return [Trail] self for chaining (no-op if target not found)
    def insert_after(target_name, name, path = nil)
      index = find_index_by_name(target_name)
      @crumbs.insert(index + 1, Crumb.new(name, path)) if index
      self
    end

    # Inserts a breadcrumb before an existing one.
    #
    # @param target_name [String] the name of the crumb to insert before
    # @param name [String] the breadcrumb label
    # @param path [String, nil] the breadcrumb URL
    # @return [Trail] self for chaining (no-op if target not found)
    def insert_before(target_name, name, path = nil)
      index = find_index_by_name(target_name)
      @crumbs.insert(index, Crumb.new(name, path)) if index
      self
    end

    # Removes a breadcrumb by name.
    #
    # @param name [String] the name of the crumb to remove
    # @return [Trail] self for chaining
    def remove(name)
      @crumbs.reject! { _1.name == name }
      self
    end

    # Replaces a breadcrumb by name.
    #
    # @param target_name [String] the name of the crumb to replace
    # @param name [String] the new breadcrumb label
    # @param path [String, nil] the new breadcrumb URL
    # @return [Trail] self for chaining (no-op if target not found)
    def replace(target_name, name, path = nil)
      index = find_index_by_name(target_name)
      @crumbs[index] = Crumb.new(name, path) if index
      self
    end

    # Checks if a breadcrumb with the given name exists.
    #
    # @param name [String] the name to search for
    # @return [Boolean]
    def include?(name) = @crumbs.any? { _1.name == name }

    # Finds a breadcrumb by name.
    #
    # @param name [String] the name to search for
    # @return [Crumb, nil] the breadcrumb or nil if not found
    def find(name) = @crumbs.find { _1.name == name }

    # Removes all breadcrumbs from the trail.
    #
    # @return [Trail] self for chaining
    def clear
      @crumbs.clear
      self
    end

    # Iterates over each breadcrumb in the trail.
    #
    # @yield [Crumb] each breadcrumb
    # @return [Enumerator] if no block given
    def each(&block)
      return enum_for(:each) { size } unless block

      @crumbs.each(&block)
    end

    # @return [Integer] number of breadcrumbs
    def size = @crumbs.size
    alias length size

    # @return [Boolean] true if trail has no breadcrumbs
    def empty? = @crumbs.empty?

    # @return [Crumb, nil] the last breadcrumb
    def last = @crumbs.last

    # @return [Crumb, nil] the first breadcrumb
    def first = @crumbs.first

    # Access a breadcrumb by index.
    #
    # @param index [Integer] the index
    # @return [Crumb, nil] the breadcrumb at that index
    def [](index) = @crumbs[index]

    # @return [Array<String>] array of breadcrumb names
    def names = @crumbs.map(&:name)

    # @return [Array<Crumb>] a copy of the internal crumbs array
    def to_a = @crumbs.dup

    # @param other [Trail] the object to compare
    # @return [Boolean]
    def ==(other) = other.is_a?(Trail) && @crumbs == other.to_a

    # Returns a developer-friendly string representation.
    #
    # @return [String] inspection string
    # @example
    #   trail.inspect
    #   #=> '#<PetitPoucet::Trail ["Home"=>"/", "Articles"=>"/articles", "Ruby Guide"=>nil]>'
    def inspect
      crumb_list = @crumbs.map { |c| "#{c.name.inspect}=>#{c.path.inspect}" }.join(', ')
      "#<PetitPoucet::Trail [#{crumb_list}]>"
    end

    private

    def find_index_by_name(name) = @crumbs.index { _1.name == name }
  end
end
