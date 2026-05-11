# frozen_string_literal: true

require 'rexml/document'

module PetitPoucet
  # Capybara-style matchers for system/feature tests that inspect rendered HTML.
  #
  # These matchers parse the breadcrumb partial's HTML structure
  # (`<nav aria-label="Breadcrumb">` containing `<li>` elements) and match on
  # text content of each `<li>`.
  #
  # @example RSpec setup in rails_helper.rb
  #   require 'petit_poucet/capybara_matchers'
  #
  #   RSpec.configure do |config|
  #     config.include PetitPoucet::CapybaraMatchers, type: :system
  #     config.include PetitPoucet::CapybaraMatchers, type: :feature
  #   end
  #
  # @example Usage in system specs
  #   visit article_path(article)
  #   expect(page).to have_breadcrumb_text("Articles")
  #   expect(page).to have_breadcrumb_list(["Home", "Articles", "My Article"])
  #
  module CapybaraMatchers
    # Matcher that checks whether a single breadcrumb text is present in the
    # rendered `<nav aria-label="Breadcrumb">`.
    #
    # @param text [String] the breadcrumb text to look for
    # @return [HaveBreadcrumbTextMatcher]
    #
    def have_breadcrumb_text(text) = HaveBreadcrumbTextMatcher.new(text)

    # Matcher that checks whether the full breadcrumb list matches exactly
    # (order-sensitive) in the rendered `<nav aria-label="Breadcrumb">`.
    #
    # @param names [Array<String>] the expected breadcrumb texts in order
    # @return [HaveBreadcrumbListMatcher]
    #
    def have_breadcrumb_list(names) = HaveBreadcrumbListMatcher.new(names)

    # @private
    module Extraction
      module_function

      # Returns the text of each `<li>` inside the breadcrumb nav, in document
      # order.  Returns an empty array when there is no breadcrumb nav or the
      # HTML is unparseable.
      def breadcrumb_texts(html)
        nav = extract_breadcrumb_nav(html)
        return [] if nav.nil?

        REXML::XPath.match(nav, './/li').map { |li| all_text(li).strip }.reject(&:empty?)
      end

      # Locates the first `<nav>` with an `aria-label` attribute in *html*,
      # assumed to be the breadcrumb nav. Returns `nil` on parse failure or
      # when no matching nav is found. Label-agnostic so translated apps
      # work without configuration.
      def extract_breadcrumb_nav(html)
        wrapped = "<root>#{html}</root>"
        doc = REXML::Document.new(wrapped)
        REXML::XPath.first(doc, '//nav[@aria-label]')
      rescue REXML::ParseException
        nil
      end

      # Recursively collects all text node values within *node*.
      def all_text(node)
        node.children.map do |child|
          if child.is_a?(REXML::Text)
            child.value
          elsif child.is_a?(REXML::Element)
            all_text(child)
          else
            ''
          end
        end.join
      end
    end

    # @private
    class HaveBreadcrumbTextMatcher
      def initialize(expected) = @expected = expected

      def matches?(page)
        @actual = Extraction.breadcrumb_texts(page.html)
        @actual.include?(@expected)
      end

      def failure_message
        "expected breadcrumb text #{@expected.inspect}\nactual breadcrumbs: #{@actual.inspect}"
      end

      def failure_message_when_negated
        "expected breadcrumb text #{@expected.inspect} not to be present\nactual breadcrumbs: #{@actual.inspect}"
      end

      def description = "have breadcrumb text #{@expected.inspect}"
    end

    # @private
    class HaveBreadcrumbListMatcher
      def initialize(expected) = @expected = expected

      def matches?(page)
        @actual = Extraction.breadcrumb_texts(page.html)
        @actual == @expected
      end

      def failure_message
        "expected breadcrumb list #{@expected.inspect}\nactual breadcrumbs: #{@actual.inspect}"
      end

      def failure_message_when_negated
        "expected breadcrumb list #{@expected.inspect} not to match"
      end

      def description = "have breadcrumb list #{@expected.inspect}"
    end
  end
end
