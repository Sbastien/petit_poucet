# frozen_string_literal: true

require 'rails/generators/base'

module PetitPoucet
  module Generators
    # Copies PetitPoucet's views into the host application so they can be
    # customized. Supports --theme to select a pre-built CSS variant.
    #
    # @example
    #   $ rails generate petit_poucet:views
    #   $ rails generate petit_poucet:views --theme=tailwind
    #   $ rails generate petit_poucet:views --theme=bootstrap
    class ViewsGenerator < Rails::Generators::Base
      THEMES = %w[default tailwind bootstrap].freeze

      class_option :theme, type: :string, default: 'default',
                           desc: "Partial theme to copy (#{THEMES.join(', ')})"

      desc 'Copy PetitPoucet views to your application for customization'

      def copy_views
        validate_theme!
        self.class.source_root(theme_source_root)
        copy_file '_breadcrumbs.html.erb', 'app/views/petit_poucet/_breadcrumbs.html.erb'
      end

      private

      def validate_theme!
        return if THEMES.include?(options[:theme])

        raise Thor::Error, "Unknown theme '#{options[:theme]}'. Valid: #{THEMES.join(', ')}"
      end

      def theme_source_root
        if options[:theme] == 'default'
          File.expand_path('../../../petit_poucet/views/petit_poucet', __dir__)
        else
          File.expand_path("../../../petit_poucet/themes/#{options[:theme]}", __dir__)
        end
      end
    end
  end
end
