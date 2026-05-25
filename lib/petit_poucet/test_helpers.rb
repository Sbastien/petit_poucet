# frozen_string_literal: true

module PetitPoucet
  # Test helpers for breadcrumbs (RSpec matchers and Minitest assertions).
  #
  # @example RSpec setup in spec_helper.rb
  #   require "petit_poucet/test_helpers"
  #
  #   RSpec.configure do |config|
  #     config.include PetitPoucet::TestHelpers, type: :controller
  #     config.include PetitPoucet::TestHelpers, type: :request
  #   end
  #
  # @example RSpec usage
  #   expect(controller).to have_breadcrumb("Articles")
  #   expect(controller).to have_breadcrumbs(["Home", "Articles"])
  #
  # @example Minitest setup in test_helper.rb
  #   require "petit_poucet/test_helpers"
  #
  #   class ActionDispatch::IntegrationTest
  #     include PetitPoucet::TestHelpers
  #   end
  #
  # @example Minitest usage
  #   assert_breadcrumb "Articles"
  #   assert_breadcrumbs ["Home", "Articles"]
  #
  module TestHelpers
    # Matcher for checking if a single breadcrumb exists.
    #
    # @param name [String] the expected breadcrumb name
    # @return [HaveBreadcrumbMatcher]
    #
    # @example
    #   expect(controller).to have_breadcrumb("Home")
    #   expect(controller).not_to have_breadcrumb("Admin")
    #
    def have_breadcrumb(name) = HaveBreadcrumbMatcher.new(name)

    # Matcher for checking exact breadcrumb sequence.
    #
    # @param names [Array<String>] the expected breadcrumb names in order
    # @return [HaveBreadcrumbsMatcher]
    #
    # @example
    #   expect(controller).to have_breadcrumbs(["Home", "Articles", "My Article"])
    #
    def have_breadcrumbs(names) = HaveBreadcrumbsMatcher.new(names)

    # @private
    class HaveBreadcrumbMatcher
      def initialize(expected_name) = @expected_name = expected_name

      def matches?(controller)
        @actual_names = controller.breadcrumbs.names
        @actual_names.include?(@expected_name)
      end

      def failure_message
        "expected breadcrumbs to include #{@expected_name.inspect}\n" \
          "actual breadcrumbs: #{@actual_names.inspect}"
      end

      def failure_message_when_negated
        "expected breadcrumbs not to include #{@expected_name.inspect}\n" \
          "actual breadcrumbs: #{@actual_names.inspect}"
      end

      def description = "have breadcrumb #{@expected_name.inspect}"
    end

    # @private
    class HaveBreadcrumbsMatcher
      def initialize(expected_names) = @expected_names = expected_names

      def matches?(controller)
        @actual_names = controller.breadcrumbs.names
        @actual_names == @expected_names
      end

      def failure_message
        "expected breadcrumbs to be #{@expected_names.inspect}\n" \
          "actual breadcrumbs: #{@actual_names.inspect}"
      end

      def failure_message_when_negated = "expected breadcrumbs not to be #{@expected_names.inspect}"

      def description = "have breadcrumbs #{@expected_names.inspect}"
    end

    # Minitest assertion for checking if a single breadcrumb exists.
    #
    # @param name [String] the expected breadcrumb name
    # @param controller [Object] the controller (defaults to @controller)
    #
    # @example
    #   assert_breadcrumb "Home"
    #
    def assert_breadcrumb(name, controller = @controller)
      actual = controller.breadcrumbs.names
      assert actual.include?(name),
             "Expected breadcrumbs to include #{name.inspect}, got: #{actual.inspect}"
    end

    # Minitest assertion for checking exact breadcrumb sequence.
    #
    # @param expected [Array<String>] the expected breadcrumb names in order
    # @param controller [Object] the controller (defaults to @controller)
    #
    # @example
    #   assert_breadcrumbs ["Home", "Articles"]
    #
    def assert_breadcrumbs(expected, controller = @controller)
      actual = controller.breadcrumbs.names
      assert_equal expected, actual, "Expected breadcrumbs to be #{expected.inspect}, got: #{actual.inspect}"
    end

    # Minitest assertion for checking that a breadcrumb does not exist.
    #
    # @param name [String] the breadcrumb name that should not exist
    # @param controller [Object] the controller (defaults to @controller)
    #
    # @example
    #   refute_breadcrumb "Admin"
    #
    def refute_breadcrumb(name, controller = @controller)
      actual = controller.breadcrumbs.names
      refute actual.include?(name),
             "Expected breadcrumbs not to include #{name.inspect}, got: #{actual.inspect}"
    end

    # Minitest assertion for checking that breadcrumbs do not match.
    #
    # @param unexpected [Array<String>] the breadcrumb names that should not match
    # @param controller [Object] the controller (defaults to @controller)
    #
    # @example
    #   refute_breadcrumbs ["Admin", "Settings"]
    #
    def refute_breadcrumbs(unexpected, controller = @controller)
      actual = controller.breadcrumbs.names
      refute actual == unexpected,
             "Expected breadcrumbs not to be #{unexpected.inspect}"
    end
  end
end
